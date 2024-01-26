//
//  PlayerQueue.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import DequeModule
import Foundation
import HarmonyKit

class PlayerQueue: NSObject, ObservableObject {
    @Published var songs: Deque<Song> = Deque()
    private(set) var currentSongIndex: Int = 0

    override public init() {
        super.init()
    }

    public init(songs: [Song], containingCurrentSong currentSong: Song? = nil) {
        self.songs = Deque(songs)
        if let currentSong = currentSong {
            currentSongIndex = songs.firstIndex(of: currentSong) ?? 0
        }
        super.init()
    }

    func backward() -> Song? {
        guard currentSongIndex > 0 else { return nil }
        currentSongIndex -= 1
        return songs[currentSongIndex]
    }

    func forward() -> Song? {
        guard currentSongIndex < songs.count - 1 else { return nil }
        currentSongIndex += 1
        return songs[currentSongIndex]
    }

    func addCurrentSong(_ song: Song, withFutureSongs futureSongs: [Song]) {
        let atSongsEnd = currentSongIndex == songs.count - 1
        let gotNewCurrentSong = songs.count == 0 || songs[currentSongIndex] != song
        if atSongsEnd {
            if gotNewCurrentSong {
                appendNewCurrentSong(song: song)
            }
            songs.append(contentsOf: futureSongs)
        } else {
            let firstIndexToDrop = currentSongIndex + 1
            songs.remove(atOffsets: IndexSet(firstIndexToDrop...songs.count - 1))

            if gotNewCurrentSong {
                appendNewCurrentSong(song: song)
            }
            songs.append(contentsOf: futureSongs)
        }
    }

    private func appendNewCurrentSong(song: Song) {
        currentSongIndex = max(songs.count - 1, 0)
        songs.append(song)
    }
}
