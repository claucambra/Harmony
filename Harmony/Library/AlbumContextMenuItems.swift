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
        Button {
            playNextAlbum(album)
        } label: {
            Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }
        if !album.downloaded {
            Button {
                fetchAlbum(album)
            } label: {
                Label("Keep available offline", systemImage: "square.and.arrow.down")
            }
        } else if album.downloaded {
            Button(role: .destructive) {
                evictAlbum(album)
            } label: {
                Label("Remove offline copy", systemImage: "trash")
            }
        }
    }
}

