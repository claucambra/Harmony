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
    private var lastSongIndex: Int { songs.count - 1 }
    private var nextSongIndex: Int { currentSongIndex + 1 }
    private var proposedCurrentEndHitIndex: Int { max(songs.count, 2) }
    private var currentIndexIsAtLoadTriggerBounds: Bool {
        songIndexIsWithinLoadTriggerBounds(currentSongIndex)
    }

    private func songIndexIsWithinLoadTriggerBounds(_ index: Int) -> Bool {
        return index >= lastSongIndex - PlayerQueue.defaultPageSize
    }

    func backward() -> Song? {
        guard currentSongIndex > 0 else { return nil }
        currentSongIndex -= 1
        return songs[currentSongIndex]
    }

    func forward() -> Song? {
        if currentIndexIsAtLoadTriggerBounds {
            loadNextPage(nextPageSize: 1)
        }
        return moveForward()
    }

    private func moveForward() -> Song? {
        guard currentSongIndex < lastSongIndex else { return nil }
        currentSongIndex += 1
        return songs[currentSongIndex]
    }

    private func loadNextPageOfRepeatingQueue(nextPageSize: Int) {
        guard nextPageSize > 0, !songs.isEmpty, let endHitIndex = endHitIndex else { return }

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

    private func loadNextPageOfRepeatingCurrentSong(nextPageSize: Int) {
        guard nextPageSize > 0, !songs.isEmpty else { return }
        let currentSong = songs[currentSongIndex]
        for _ in 1...nextPageSize {
            songs.append(currentSong.clone())
        }
    }

    private func loadNextPageFromResults(nextPageSize: Int) {
        guard nextPageSize > 0, let results = results, let lastQueueSongIndex = results.firstIndex(
            where: { $0.identifier == songs.last?.identifier }
        ) else { return }

        let nextResultIndex = results.index(after: lastQueueSongIndex)
        let finalResultIndex = results.count - 1
        guard nextResultIndex < finalResultIndex else { return }

        let firstResultIndex = min(nextResultIndex, finalResultIndex)
        let lastResultIndex = min(nextResultIndex + nextPageSize - 1, finalResultIndex)

        for i in (firstResultIndex...lastResultIndex) {
            guard let song = results[i].toSong() else { continue }
            songs.append(song)
            endHitIndex = nil  // We have added new songs so impossible to be at end index now
        }

        if lastResultIndex == finalResultIndex {
            endHitIndex = proposedCurrentEndHitIndex
        }
    }

    private func loadNextPage(nextPageSize: Int = PlayerQueue.defaultPageSize) {
        // Handle current song repetition first
        guard repeatState != .currentSong else {
            loadNextPageOfRepeatingCurrentSong(nextPageSize: nextPageSize)
            return
        }

        // We haven't hit the end of the results yet, load more
        if endHitIndex == nil {
            loadNextPageFromResults(nextPageSize: nextPageSize)
        }

        // We have hit the end of the results, start loading in repeating songs
        if repeatState == .queue, endHitIndex != nil {
            loadNextPageOfRepeatingQueue(nextPageSize: nextPageSize)
        }
    }

    func loadNextPageIfNeeded(song: Song) {
        guard let songIndex = songs.lastIndex(where: { $0.id == song.id }),
              lastSongIndex - songIndex <= PlayerQueue.viewLoadTriggeringIndex else { return }
        loadNextPage()
    }

    func clear(fromIndex: Int = 0) {
        guard !songs.isEmpty else { return }
        assert(fromIndex > 0, "Provided index should be larger than 0")
        guard fromIndex <= lastSongIndex else { return }
        songs.remove(atOffsets: IndexSet(fromIndex...lastSongIndex))
    }

    func addCurrentSong(_ song: Song, dbSong: DatabaseSong, parentResults: Results<DatabaseSong>) {
        results = parentResults

        let songId = song.identifier
        if songs.isEmpty || songs[currentSongIndex].identifier != songId {
            currentSongIndex += 1
            songs.insert(song, at: currentSongIndex)
            endHitIndex = nil
        }

        if songs.count > 1, currentSongIndex < lastSongIndex {
            clear(fromIndex: nextSongIndex)
        }

        if parentResults.last?.identifier == song.identifier {
            endHitIndex = proposedCurrentEndHitIndex
        }

        loadNextPage()
    }

    func reloadNextSongs() {
        guard !songs.isEmpty else { return }
        clear(fromIndex: nextSongIndex)
        if results?.last?.identifier == songs[currentSongIndex].identifier {
            endHitIndex = proposedCurrentEndHitIndex
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
        if currentSongIndex == lastSongIndex {
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
