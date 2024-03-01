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
                    .frame(height: UIMeasurements.largeArtworkHeight)

                VStack(alignment: .leading) {
                    Text(album.title.isEmpty ? "Unknown album" : album.title)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.leading)
                    Text(album.artist ?? "Unknown artist")
                        .font(.title)
                        .multilineTextAlignment(.leading)
                    Text(album.genre == nil || album.genre!.isEmpty
                            ? "Unknown genre"
                            : album.genre ?? "Unknown genre")
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                }
            }
            .listRowInsets(.init(
                top: pagePadding,
                leading: pagePadding,
                bottom: UIMeasurements.largePadding,
                trailing: pagePadding
            ))
            .listRowSeparator(.hidden)

            ForEach(album.songs) { song in
                Text(song.title)
                    .listRowInsets(.init(
                        top: 0,
                        leading: pagePadding,
                        bottom: 0,
                        trailing: pagePadding
                    ))
            }
        }
        .listStyle(.plain)
    }
}
