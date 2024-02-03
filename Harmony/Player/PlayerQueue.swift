//
//  PlayerQueue.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import DequeModule
import Foundation
import HarmonyKit
import RealmSwift

@MainActor
class PlayerQueue: ObservableObject {
    enum RepeatState { case disabled, queue, currentSong }
    static let defaultPageSize = 10
    static let viewLoadTriggeringIndex = 5
    @Published var results: Results<DatabaseSong>? // TODO: Listen to changes to this and upd. songs
    @Published var songs: Deque<Song> = Deque()
    @Published var repeatState: RepeatState = .disabled {
        didSet { reloadNextSongs() }
    }
    private(set) var currentSongIndex: Int = -1
    private var endHitIndex: Int?  // When we first start repeating

    private func songIndexIsWithinLoadTriggerBounds(_ index: Int) -> Bool {
        return index >= (songs.count - 1) - PlayerQueue.defaultPageSize
    }

    private func currentIndexIsAtLoadTriggerBounds() -> Bool {
        return songIndexIsWithinLoadTriggerBounds(currentSongIndex)
    }

    func backward() -> Song? {
        guard currentSongIndex > 0 else { return nil }
        currentSongIndex -= 1
        return songs[currentSongIndex]
    }

    func forward() -> Song? {
        if currentIndexIsAtLoadTriggerBounds() {
            loadNextPage(nextPageSize: 1)
        }
        return moveForward()
    }

    private func moveForward() -> Song? {
        guard currentSongIndex < songs.count - 1 else { return nil }
        currentSongIndex += 1
        return songs[currentSongIndex]
    }

    private func loadNextPage(nextPageSize: Int = PlayerQueue.defaultPageSize) {
        guard nextPageSize > 0, let results = results else { return }

        guard repeatState != .currentSong else {
            guard songs.count > 0 else { return }
            let currentSong = songs[currentSongIndex]
            for _ in 1...nextPageSize {
                songs.append(currentSong.clone())
            }
            return
        }

        if endHitIndex == nil {
            guard let lastQueueSongIndex = results.firstIndex(
                where: { $0.identifier == songs.last?.identifier }
            ) else { return }
            let nextSongIndex = results.index(after: lastQueueSongIndex)
            let finalSongIndex = results.count - 1
            guard nextSongIndex < finalSongIndex else { return }
            let firstSongIndex = min(nextSongIndex, finalSongIndex)
            // Since we start at +1, remove 1
            let lastSongIndex = min(nextSongIndex + nextPageSize - 1, finalSongIndex)

            for i in (firstSongIndex...lastSongIndex) {
                guard let song = results[i].toSong() else { continue }
                songs.append(song)
                endHitIndex = nil  // We have added new songs so impossible to be at end index now
            }

            if lastSongIndex == finalSongIndex {
                endHitIndex = max(songs.count, 2)
            }
        }

        if repeatState == .queue {
            guard songs.count > 0, let endHitIndex = endHitIndex else { return }
            let nextSongIndex = songs.count
            let pageEndSongIndex = nextSongIndex + nextPageSize - 1

            for unboundedIndex in nextSongIndex...pageEndSongIndex {
                let boundedIndex = unboundedIndex.remainderReportingOverflow(
                    dividingBy: endHitIndex
                ).partialValue
                let repeatingSong = songs[boundedIndex]
                songs.append(repeatingSong.clone())
            }
        }
    }

    func loadNextPageIfNeeded(song: Song) {
        guard let songIdx = songs.lastIndex(where: { $0.id == song.id }),
              (songs.count - 1) - songIdx <= PlayerQueue.viewLoadTriggeringIndex else { return }
        loadNextPage()
    }

    func clear(fromIndex: Int = 0) {
        guard songs.count > 0 else { return }
        assert(fromIndex > 0, "Provided index should be larger than 0")
        guard fromIndex <= songs.count - 1 else { return }
        songs.remove(atOffsets: IndexSet(fromIndex...songs.count - 1))
    }

    func addCurrentSong(_ song: Song, dbSong: DatabaseSong, parentResults: Results<DatabaseSong>) {
        results = parentResults

        let songId = song.identifier
        if songs.count == 0 || songs[currentSongIndex].identifier != songId {
            currentSongIndex += 1
            songs.insert(song, at: currentSongIndex)
            endHitIndex = nil
        }

        if songs.count > 1, currentSongIndex < songs.count - 1 {
            clear(fromIndex: currentSongIndex + 1)
        }

        if parentResults.last?.identifier == song.identifier {
            endHitIndex = max(songs.count, 2)
        }

        loadNextPage()
    }

    func reloadNextSongs() {
        guard songs.count > 0 else { return }
        clear(fromIndex: currentSongIndex + 1)
        if results?.last?.identifier == songs[currentSongIndex].identifier {
            endHitIndex = max(songs.count, 2)
        } else {
            endHitIndex = nil
        }
        loadNextPage()
    }

    func moveToSong(instanceId: ObjectIdentifier) -> Song? {
        guard let songIdx = songs.firstIndex(where: { song in song.id == instanceId }) else {
            return nil
        }
        currentSongIndex = songIdx
        if currentSongIndex == songs.count - 1 {
            loadNextPage()
        }
        return songs[songIdx]
    }

    func cycleRepeatState() {
        switch repeatState {
        case .disabled:
            repeatState = .queue
        case .queue:
            repeatState = .currentSong
        case .currentSong:
            repeatState = .disabled
        }
    }
}
