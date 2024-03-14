//
//  AlbumContextMenuItems.swift
//  Harmony
//
//  Created by Claudio Cambra on 14/3/24.
//

import HarmonyKit
import SwiftUI

struct AlbumContextMenuItems: View {
    @ObservedObject var queue = PlayerController.shared.queue
    let album: Album

    var body: some View {
        let sortedSongs = album.songs.sorted {
            guard $0.trackNumber != 0, $1.trackNumber != 0 else { return $0.title < $1.title }
            return $0.trackNumber < $1.trackNumber
        }

        Button {
            for song in sortedSongs {
                queue.insertNextSong(song)
            }
        } label: {
            Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }
        if !album.downloaded {
            Button {
                for song in album.songs {
                    let backend = BackendsModel.shared.backends[song.backendId]
                    Task { await backend?.fetchSong(song) }
                }
            } label: {
                Label("Keep available offline", systemImage: "square.and.arrow.down")
            }
        } else if album.downloaded {
            Button(role: .destructive) {
                for song in album.songs {
                    let backend = BackendsModel.shared.backends[song.backendId]
                    Task { await backend?.evictSong(song) }
                }
            } label: {
                Label("Remove offline copy", systemImage: "trash")
            }
        }
    }
}

