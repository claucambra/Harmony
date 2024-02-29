//
//  AlbumDetailView.swift
//  Harmony
//
//  Created by Claudio Cambra on 1/3/24.
//

import HarmonyKit
import SwiftUI

struct AlbumDetailView: View {
    let album: Album

    var body: some View {
        List {
            Rectangle().foregroundStyle(.blue).frame(width: 29, height: 30)
            ForEach(album.songs) { song in
                Text(song.title)
            }
        }
    }
}
