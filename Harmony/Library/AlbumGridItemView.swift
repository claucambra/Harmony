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

    @State var hoveredArtwork = false

    var body: some View {
        let titleString = album.title == "" ? fallbackTitle : album.title
        let artistString = album.artist == nil || album.artist == ""
            ? fallbackArtist
            : album.artist ?? fallbackArtist
        VStack {
            ZStack(alignment: .bottom) {
                BorderedArtworkView(artwork: album.artwork)
                    .frame(maxWidth: .infinity)
                    .blur(radius: hoveredArtwork ? UIMeasurements.smallBlurRadius : 0.0)
                    .animation(UIMeasurements.hoverAnimation, value: hoveredArtwork)
                RoundedRectangle(cornerRadius: UIMeasurements.cornerRadius)
                    .foregroundStyle(.gray)
                    .opacity(hoveredArtwork ? UIMeasurements.hoverOverlayOpacity : 0.0)
                    .animation(UIMeasurements.hoverAnimation, value: hoveredArtwork)
            }
            Text(titleString)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            Text(artistString)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .onHover { inside in
            hoveredArtwork = inside
        }
    }
}
