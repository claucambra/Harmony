//
//  ArtistsSplitView.swift
//  Harmony
//
//  Created by Claudio Cambra on 12/3/24.
//

import HarmonyKit
import SwiftUI

struct ArtistsSplitView: View {
    @Environment(\.floatingBarHeight) var floatingBarHeight
    @Binding var searchText: String
    @Binding var showOnlineSongs: Bool
    @Binding var albumSortOrder: SortDescriptor<Album>
    @State var selection: Artist?

    var body: some View {
        NavigationSplitView {
            ArtistsListView(selection: $selection)
                .navigationTitle("Artists")
                .safeAreaPadding(.bottom, floatingBarHeight)
        } detail: {
            NavigationStack {
                if let artist = selection {
                    AlbumsGridView(
                        albums: artist.albums,
                        searchText: $searchText,
                        showOnlineSongs: $showOnlineSongs,
                        sortOrder: $albumSortOrder
                    )
                    .navigationTitle(artist.name)
                }
            }
            .safeAreaPadding(.bottom, floatingBarHeight)
        }
    }
}
