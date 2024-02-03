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
    @Published var results: Results<DatabaseSong>? {
        // TODO: Listen to changes to this and upd. songs
        didSet { shuffledIdentifiers = [] } // Shuffle freshly
    }
    @Published var songs: Deque<Song> = Deque()
    @Published var shuffleEnabled = false {
        didSet { reloadNextSongs() }
    }
    @Published var repeatState: RepeatState = .disabled {
        didSet { reloadNextSongs() }
    }
    private var currentSongIndex: Int = -1
    private var shuffledIdentifiers: Set<String> = []
    private var addedSongResultsIndex: Int = -1
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
        guard nextPageSize > 0,
                let results = results,
                !results.isEmpty,
                let lastQueueSongIndex = results.firstIndex(
                    where: { $0.identifier == songs.last?.identifier }
        ) else { return }

        guard !shuffleEnabled else {
            guard addedSongResultsIndex + 1 < results.count - 1 else { return }
            let eligibleRange = addedSongResultsIndex + 1...results.count - 1
            let electedIndices: Set<Int> = []
            let afterAddedSongCount = results.count - (addedSongResultsIndex + 1)
            var remainingResults = afterAddedSongCount - shuffledIdentifiers.count
            var insertedCount = 0

            while remainingResults > 0, insertedCount < nextPageSize  {
                guard let randomIndex = eligibleRange.randomElement(),
                      !electedIndices.contains(randomIndex) else { continue }
                let randomDbSong = results[randomIndex]
                let randomDbSongIdentifier = randomDbSong.identifier
                guard !shuffledIdentifiers.contains(randomDbSongIdentifier),
                      let randomSong = randomDbSong.toSong() else { continue }
                songs.append(randomSong)
                shuffledIdentifiers.insert(randomDbSongIdentifier)
                remainingResults -= 1
                insertedCount += 1
            }

            if remainingResults == 0 {
                endHitIndex = proposedCurrentEndHitIndex
            }
            return
        }

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

    @discardableResult func clear(fromIndex: Int = 0) -> [String]? {
        guard !songs.isEmpty else { return nil }
        assert(fromIndex > 0, "Provided index should be larger than 0")
        guard fromIndex <= lastSongIndex else { return nil }

        let indexRange = fromIndex...lastSongIndex
        var removedSongsIdentifiers: [String] = []
        for i in indexRange {
            let identifier = songs[i].identifier
            removedSongsIdentifiers.append(identifier)
        }
        songs.remove(atOffsets: IndexSet(indexRange))
        return removedSongsIdentifiers
    }

    func addCurrentSong(_ song: Song, dbSong: DatabaseSong, parentResults: Results<DatabaseSong>) {
        results = parentResults

        if songs.isEmpty || songs[currentSongIndex].identifier != song.identifier {
            currentSongIndex += 1
            addedSongResultsIndex = parentResults.lastIndex(of: dbSong)!
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
        let removedSongsIdentifiers = clear(fromIndex: nextSongIndex)

        if results?.last?.identifier == songs[currentSongIndex].identifier {
            endHitIndex = proposedCurrentEndHitIndex
        } else {
            endHitIndex = nil
        }

        if let removedSongsIdentifiers = removedSongsIdentifiers,
           !removedSongsIdentifiers.isEmpty,
           !shuffledIdentifiers.isEmpty
        {
            for songIdentifier in removedSongsIdentifiers {
                shuffledIdentifiers.remove(songIdentifier)
            }
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
