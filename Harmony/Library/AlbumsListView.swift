//
//  AlbumsListView.swift
//  Harmony
//
//  Created by Claudio Cambra on 14/3/24.
//

import HarmonyKit
import SwiftUI

struct AlbumsListView: View {
    @Environment(\.floatingBarHeight) var floatingBarHeight
    let albums: [Album]
    @Binding var searchText: String
    @Binding var showOnlineSongs: Bool
    @Binding var sortOrder: SortDescriptor<Album>
    @State private var selection: Set<Song.ID> = []

    #if os(macOS)
    private let horizontalPadding = UIMeasurements.veryLargePadding
    private let verticalPadding = UIMeasurements.veryLargePadding
    #else
    private let horizontalPadding = UIMeasurements.largePadding
    private let verticalPadding = UIMeasurements.largePadding
    #endif

    var body: some View {
        List(selection: $selection) {
            ForEach(albums) { album in
                Section {
                    ForEach(album.songs) { song in
                        SongListItemView(
                            song: song,
                            displayArtwork: false,
                            displayArtist: false,
                            displayTrackNumber: true
                        )
                        .listRowInsets(.init(
                            top: UIMeasurements.smallPadding,
                            leading: horizontalPadding,
                            bottom: UIMeasurements.smallPadding,
                            trailing: horizontalPadding
                        ))
                    }
                } header: {
                    AlbumHeaderView(
                        album: album,
                        minArtworkWidth: UIMeasurements.mediumLargeArtworkHeight,
                        maxArtworkWidth: UIMeasurements.mediumLargeArtworkHeight
                    )
                    .foregroundStyle(.foreground)
                    .padding(.init(
                        top: verticalPadding,
                        leading: horizontalPadding,
                        bottom: verticalPadding,
                        trailing: horizontalPadding
                    ))
                }
            }
        }
        .listStyle(.plain)
        #if !os(macOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer)
        #endif
        .toolbar {
            ToolbarItem {
                Menu {
                    Toggle(isOn: $showOnlineSongs) {
                        Label("Undownloaded songs", systemImage: "cloud")
                    }
                    Button("Title") { sortOrder = SortDescriptor(\Album.title) }
                    Button("Artist") { sortOrder = SortDescriptor(\Album.artist) }
                    Button("Year") { sortOrder = SortDescriptor(\Album.year) }
                } label: {
                    Label("Sort and filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}
