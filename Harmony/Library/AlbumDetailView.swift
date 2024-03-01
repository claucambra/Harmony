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
    let horizontalPadding = UIMeasurements.ultraLargePadding
    let verticalPadding = UIMeasurements.veryLargePadding
    #else
    let horizontalPadding = UIMeasurements.largePadding
    let verticalPadding = UIMeasurements.largePadding
    #endif

    @State var selection: Set<Song.ID> = []

    var body: some View {
        List(selection: $selection) {
            HStack(spacing: UIMeasurements.largePadding) {
                BorderedArtworkView(artwork: album.artwork)
                    .frame(maxHeight: UIMeasurements.largeArtworkHeight)
                    .shadow(radius: UIMeasurements.shadowRadius)

                VStack(alignment: .leading) {
                    Spacer()
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
                    Spacer()
                    Button {
                        guard let firstSong = album.songs.first else { return }
                        let controller = PlayerController.shared
                        controller.playSong(firstSong, withinSongs: album.songs.lazy)
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .foregroundStyle(.foreground)
                            .padding([.leading, .trailing], UIMeasurements.largePadding)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(.init(
                top: verticalPadding,
                leading: horizontalPadding,
                bottom: verticalPadding,
                trailing: horizontalPadding
            ))
            .listRowSeparator(.hidden)

            ForEach(album.songs) { song in
                SongListItemView(song: song, displayArtwork: false, displayArtist: false)
                    .listRowInsets(.init(
                        top: UIMeasurements.smallPadding,
                        leading: horizontalPadding,
                        bottom: UIMeasurements.smallPadding,
                        trailing: horizontalPadding
                    ))
            }
        }
        .listStyle(.plain)
        .contextMenu(forSelectionType: Song.ID.self) { items in
            contextMenuItemsForSongs(ids: items, songs: album.songs)
        } primaryAction: { ids in
            playSongsFromIds(ids, songs: album.songs)
        }
    }
}
