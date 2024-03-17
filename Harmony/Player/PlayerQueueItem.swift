//
//  PlayerQueueItem.swift
//  Harmony
//
//  Created by Claudio Cambra on 17/3/24.
//

import Foundation
import HarmonyKit

class PlayerQueueItem: Identifiable, Equatable {
    static func == (lhs: PlayerQueueItem, rhs: PlayerQueueItem) -> Bool {
        lhs.id == rhs.id
    }

    let song: Song
    var identifier: String { song.identifier }
    var title: String { song.title }
    var album: String { song.album }
    var artist: String { song.artist }
    var artwork: Data? { song.artwork }
    var isPlayNext: Bool {
        get { song.isPlayNext }
        set { song.isPlayNext = newValue }
    }

    init(song: Song) {
        self.song = song
    }

    func clone() -> PlayerQueueItem {
        return PlayerQueueItem(song: song)
    }
}
