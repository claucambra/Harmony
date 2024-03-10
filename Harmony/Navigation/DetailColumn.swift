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
    @State var secondaryToolbarHeight: CGFloat = 0.0

    var body: some View {
        switch selection ?? .songs {
        case .songs:
            SongsTable(searchText: $searchText, showOnlineSongs: $showOnlineSongs)
                .navigationTitle("Songs")
        case .albums:
            AlbumsGridView(searchText: $searchText, showOnlineSongs: $showOnlineSongs)
                .navigationTitle("Albums")
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
                selection: $selection, searchText: $searchText, showOnlineSongs: $showOnlineSongs
            )
        }
    }
    static var previews: some View {
        Preview()
    }
}
