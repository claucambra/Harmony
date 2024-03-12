//
//  DetailColumn.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import HarmonyKit
import SwiftUI

struct DetailColumn: View {
    @Binding var selection: Panel?
    @Binding var searchText: String
    @Binding var showOnlineSongs: Bool
    @Binding var albumSort: SortDescriptor<Album>
    @State var secondaryToolbarHeight: CGFloat = 0.0

    var body: some View {
        switch selection ?? .songs {
        case .songs:
            SongsTable(searchText: $searchText, showOnlineSongs: $showOnlineSongs)
                .navigationTitle("Songs")
        case .albums:
            AlbumsGridView(
                searchText: $searchText,
                showOnlineSongs: $showOnlineSongs,
                sortOrder: $albumSort
            )
            .navigationTitle("Albums")
        case .artists:
            ArtistsListView()
        case .settings:
            EmptyView()
        }
    }
}

struct DetailColumn_Previews: PreviewProvider {
    struct Preview: View {
        @State private var selection: Panel? = .songs
        @State private var searchText = "Search text"
        @State private var showOnlineSongs = true

        var body: some View {
            DetailColumn(
                selection: $selection, 
                searchText: $searchText,
                showOnlineSongs: $showOnlineSongs,
                albumSort: .constant(.init(\Album.title))
            )
        }
    }
    static var previews: some View {
        Preview()
    }
}
