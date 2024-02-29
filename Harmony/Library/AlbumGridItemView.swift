//
//  AlbumGridItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 29/2/24.
//

import HarmonyKit
import SwiftUI

struct AlbumGridItemView: View {
    let album: Album

    var body: some View {
        VStack {
            BorderedArtworkView(artwork: album.artwork)
                .frame(maxWidth: .infinity)
            Text(album.title)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            Text(album.artist ?? "Unknown artist")
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }
}
