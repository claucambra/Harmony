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
    let fallbackTitle = "Unknown album"
    let fallbackArtist = "Unknown artist"

    var body: some View {
        let titleString = album.title == "" ? fallbackTitle : album.title
        let artistString = album.artist == nil || album.artist == ""
            ? fallbackArtist
            : album.artist ?? fallbackArtist
        VStack {
            BorderedArtworkView(artwork: album.artwork)
                .frame(maxWidth: .infinity)
            Text(titleString)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            Text(artistString)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }
}
