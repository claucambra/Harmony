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

    #if os(macOS)
    let pagePadding = UIMeasurements.ultraLargePadding
    #else
    let pagePadding = UIMeasurements.largePadding
    #endif

    @State var selection: Set<Song.ID> = []

    var body: some View {
        List(selection: $selection) {
            HStack(spacing: UIMeasurements.largePadding) {
                BorderedArtworkView(artwork: album.artwork)
                    .frame(maxHeight: UIMeasurements.largeArtworkHeight)
                    .shadow(radius: UIMeasurements.shadowRadius)

                VStack(alignment: .leading) {
                    Text(album.title.isEmpty ? "Unknown album" : album.title)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(album.artist ?? "Unknown artist")
                        .font(.title)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(album.genre == nil || album.genre!.isEmpty
                            ? "Unknown genre"
                            : album.genre ?? "Unknown genre")
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(.init(
                top: UIMeasurements.largePadding,
                leading: pagePadding,
                bottom: UIMeasurements.largePadding,
                trailing: pagePadding
            ))
            .listRowSeparator(.hidden)

            ForEach(album.songs) { song in
                SongListItemView(song: song, displayArtwork: false, displayArtist: false)
                    .listRowInsets(.init(
                        top: UIMeasurements.smallPadding,
                        leading: pagePadding,
                        bottom: UIMeasurements.smallPadding,
                        trailing: pagePadding
                    ))
            }
        }
        .listStyle(.plain)
    }
}
