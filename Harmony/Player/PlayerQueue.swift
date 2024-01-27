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
    @Published var results: Results<DatabaseSong>?
    @Published var songs: Deque<Song> = Deque()
    private(set) var currentSongIndex: Int = -1

    override public init() {
        super.init()
    }

    func backward() -> Song? {
        guard currentSongIndex > 0 else { return nil }
        currentSongIndex -= 1
        return songs[currentSongIndex]
    }

    func forward() -> Song? {
        if currentSongIndex >= (songs.count - 2) - PlayerQueue.defaultPageSize {
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
        }
    }

    func loadNextPageIfNeeded(song: Song) {
        guard let songIdx = songs.lastIndex(of: song),
              (songs.count - 1) - songIdx <= PlayerQueue.viewLoadTriggeringIndex else { return }
        loadNextPage()
    }

    func addCurrentSong(_ song: Song, dbSong: DatabaseSong, parentResults: Results<DatabaseSong>) {
        results = parentResults

        if (songs.count > 0) {
            let firstIndexToDrop = currentSongIndex + 1
            songs.remove(atOffsets: IndexSet(firstIndexToDrop...songs.count - 1))
        }

        let songId = song.identifier
        let gotNewCurrentSong = songs.count == 0 || songs[currentSongIndex].identifier != songId
        if gotNewCurrentSong {
            appendNewCurrentSong(song: song)
        }

        loadNextPage()
    }

    private func appendNewCurrentSong(song: Song) {
        currentSongIndex = max(songs.count - 1, 0)
        songs.append(song)
    }
}
