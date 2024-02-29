//
//  AlbumsGridView.swift
//  Harmony
//
//  Created by Claudio Cambra on 28/2/24.
//

import HarmonyKit
import SwiftData
import SwiftUI

struct AlbumsGridView: View {
    @Query(sort: \Album.title) var albums: [Album]
    @Binding var searchText: String
    @Binding var showOnlineSongs: Bool
    @State var selection: Set<Album.ID> = []
    let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 300), spacing: UIMeasurements.largePadding)
    ]

    init(searchText: Binding<String>, showOnlineSongs: Binding<Bool>) {
        _searchText = searchText
        _showOnlineSongs  = showOnlineSongs
        let searchTextVal = searchText.wrappedValue
        let showOnlineSongsVal = showOnlineSongs.wrappedValue

        _albums = Query(
            filter: #Predicate {
                if searchTextVal.isEmpty, showOnlineSongsVal {
                    true
                } else if !searchTextVal.isEmpty, showOnlineSongsVal {
                    $0.title.localizedStandardContains(searchTextVal)
                } else if searchTextVal.isEmpty, !showOnlineSongsVal {
                    $0.songs.contains(where: { $0.downloaded })
                } else {
                    $0.title.localizedStandardContains(searchTextVal) && 
                    $0.songs.contains(where: { $0.downloaded })
                }
            },
            sort: \Album.title
        )
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: UIMeasurements.largePadding) {
                ForEach(albums) { album in
                    AlbumGridItemView(album: album)
                }
            }
            .padding([.top, .bottom], UIMeasurements.veryLargePadding)
            .padding([.leading, .trailing], UIMeasurements.ultraLargePadding)
        }
        .background(.background)
    }
}
