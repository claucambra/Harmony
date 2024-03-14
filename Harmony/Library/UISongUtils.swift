//
//  UISongUtils.swift
//  Harmony
//
//  Created by Claudio Cambra on 1/3/24.
//

import HarmonyKit
import SwiftUI
import OSLog

@ViewBuilder
func contextMenuItemsForSongs(ids: Set<Song.ID>, songs: [Song]) -> some View {
    if let songId = ids.first {
        contextMenuItemsForSong(id: songId, songs: songs)
    }
}

@ViewBuilder
func contextMenuItemsForSong(id: Song.ID, songs: [Song]) -> some View {
    if let song = songs.filter({ $0.id == id }).first {
        SongContextMenuItems(song: song)
    }
}

@MainActor
func playSongsFromIds(_ ids: Set<Song.ID>, songs: [Song]) {
    for id in ids {
        guard let song = songs.filter({ $0.id == id }).first else {
            Logger.songsTable.error("Could not find song with id")
            return
        }
        PlayerController.shared.playSong(song, withinSongs: songs)
    }
}

func fetchSong(_ song: Song) {
    let backend = BackendsModel.shared.backends[song.backendId]
    Task { await backend?.fetchSong(song) }
}

func evictSong(_ song: Song) {
    let backend = BackendsModel.shared.backends[song.backendId]
    Task { await backend?.evictSong(song) }
}
