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
class PlayerQueue: NSObject, ObservableObject {
    static let defaultPageSize = 20
    static let viewLoadTriggeringIndex = 10
    @Published var results: Results<DatabaseSong>? // TODO: Listen to changes to this and upd. songs
    @Published var songs: Deque<Song> = Deque()
    private(set) var currentSongIndex: Int = -1
    private var endHitIndex: Int?  // When we first start repeating

    override public init() {
        super.init()
    }

    private func songIndexIsWithinLoadTriggerBounds(_ index: Int) -> Bool {
        return index >= (songs.count - 1) - PlayerQueue.defaultPageSize
    }

    private func currentIndexIsAtLoadTriggerBounds() -> Bool {
        return songIndexIsWithinLoadTriggerBounds(currentSongIndex)
    }

    private func nextRepeatingSongIndex() -> Int? {
        guard songs.count > 0 else { return nil }
        if endHitIndex == nil {
            endHitIndex = max(songs.count - 1, 2)
        }
        return (currentSongIndex + 1).remainderReportingOverflow(
            dividingBy: endHitIndex!
        ).partialValue
    }

    func backward() -> Song? {
        guard currentSongIndex > 0 else { return nil }
        currentSongIndex -= 1
        return songs[currentSongIndex]
    }

    func forward(repeatEnabled: Bool = false) -> Song? {
        if currentIndexIsAtLoadTriggerBounds(), endHitIndex == nil {
            loadNextPage(nextPageSize: 1)
        }

        if repeatEnabled, 
            currentSongIndex >= songs.count - 1,
            let nextSongIdx = nextRepeatingSongIndex() {
            // We are still at the load trigger index, which means we have loaded all available
            // results from the database. Therefore, start repeating songs in the history
            let repeatingSong = songs[nextSongIdx]
            if let dbRepeatingSong = results?.first(where: {
                $0.identifier == repeatingSong.identifier
            }), let newRepeatingSongInstance = dbRepeatingSong.toSong() {
                songs.append(newRepeatingSongInstance)
            }
        }

        return moveForward()
    }

    private func moveForward() -> Song? {
        guard currentSongIndex < songs.count - 1 else { return nil }
        currentSongIndex += 1
        return songs[currentSongIndex]
    }

    private func loadNextPage(nextPageSize: Int = PlayerQueue.defaultPageSize) {
        guard nextPageSize > 0 else { return }
        guard let results = results else { return }
        guard let lastQueueSongIdx = results.firstIndex(
            where: { $0.identifier == songs.last?.identifier }
        ) else { return }
        let nextSongIdx = results.index(after: lastQueueSongIdx)
        let finalSongIdx = results.count - 1
        guard nextSongIdx < finalSongIdx else { return }
        let firstSongIdx = min(nextSongIdx, finalSongIdx)
        let lastSongIdx = min(nextSongIdx + nextPageSize - 1, finalSongIdx)  // Since we start at +1

        for i in (firstSongIdx...lastSongIdx) {
            guard let song = results[i].toSong() else { continue }
            songs.append(song)
            endHitIndex = nil  // We have added new songs so impossible to be at end index now
        }
    }

    func loadNextPageIfNeeded(song: Song) {
        guard endHitIndex == nil,
              let songIdx = songs.lastIndex(of: song),
              (songs.count - 1) - songIdx <= PlayerQueue.viewLoadTriggeringIndex else { return }
        loadNextPage()
    }

    func addCurrentSong(_ song: Song, dbSong: DatabaseSong, parentResults: Results<DatabaseSong>) {
        results = parentResults

        let songId = song.identifier
        if songs.count == 0 || songs[currentSongIndex].identifier != songId {
            currentSongIndex += 1
            songs.insert(song, at: currentSongIndex)
            endHitIndex = nil
        }

        if (songs.count > 1) {
            let firstIndexToDrop = currentSongIndex + 1
            songs.remove(atOffsets: IndexSet(firstIndexToDrop...songs.count - 1))
        }

        loadNextPage()
    }

    func moveToSong(instanceId: ObjectIdentifier) -> Song? {
        guard let songIdx = songs.firstIndex(where: { song in song.id == instanceId }) else {
            return nil
        }
        currentSongIndex = songIdx
        return songs[songIdx]
    }

    func goToFirst() -> Song? {
        currentSongIndex = 0
        return songs[currentSongIndex]
    }

    func goToLast() -> Song? {
        currentSongIndex = songs.count - 1
        return songs[currentSongIndex]
    }
}
