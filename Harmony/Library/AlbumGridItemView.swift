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
    @State var hoveredPlayButton = false

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
                    .clipShape(RoundedRectangle(cornerRadius: UIMeasurements.cornerRadius))
                    .animation(UIMeasurements.hoverAnimation, value: hoveredArtwork)
                RoundedRectangle(cornerRadius: UIMeasurements.cornerRadius)
                    .foregroundStyle(.black)
                    .opacity(hoveredArtwork ? UIMeasurements.hoverOverlayOpacity : 0.0)
                    .animation(UIMeasurements.hoverAnimation, value: hoveredArtwork)
                if hoveredArtwork {
                    HStack {
                        Button {
                            guard let firstSong = album.songs.first else { return }
                            let controller = PlayerController.shared
                            let sortedSongs = sortedAlbumSongs(album)
                            controller.playSong(firstSong, withinSongs: sortedSongs)
                        } label: {
                            let primaryColor: Color = hoveredPlayButton ? .accentColor : .white
                            let renderMode: SymbolRenderingMode = hoveredPlayButton
                                ? .multicolor
                                : .hierarchical
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .symbolRenderingMode(renderMode)
                                .foregroundStyle(primaryColor, .white)

                        }
                        .buttonStyle(.borderless)
                        .controlSize(.large)
                        .frame(
                            width: UIMeasurements.mediumButtonSize,
                            height: UIMeasurements.mediumButtonSize
                        )
                        .onHover { inside in hoveredPlayButton = inside }
                        Spacer()
                    }
                    .padding(UIMeasurements.smallPadding)
                }
            }
            Text(titleString)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            Text(artistString)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .onHover { inside in hoveredArtwork = inside }
        .contextMenu { AlbumContextMenuItems(album: album) }
    }
}
