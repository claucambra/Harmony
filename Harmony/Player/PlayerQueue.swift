//
//  PlayerQueue.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import Foundation
import HarmonyKit

class PlayerQueue: NSObject {
    var songs: [Song] = []
    private var currentSongIndex: Int = 0

    public init(songs: [Song], containingCurrentSong currentSong: Song? = nil) {
        self.songs = songs
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
        guard currentSongIndex < songs.count else { return nil }
        currentSongIndex += 1
        return songs[currentSongIndex]
    }
}
