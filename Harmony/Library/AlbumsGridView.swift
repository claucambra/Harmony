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
    @Binding var secondaryToolbarHeight: CGFloat
    @State var selection: Set<Album.ID> = []

    #if os(macOS)
    let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 300), spacing: UIMeasurements.largePadding)
    ]
    let horizontalPadding = UIMeasurements.ultraLargePadding
    let verticalPadding = UIMeasurements.veryLargePadding
    let interItemPadding = UIMeasurements.largePadding
    #else
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 240), spacing: UIMeasurements.largePadding)
    ]
    let horizontalPadding = UIMeasurements.largePadding
    let verticalPadding = UIMeasurements.largePadding
    let interItemPadding = UIMeasurements.largePadding
    #endif

    init(
        searchText: Binding<String>,
        showOnlineSongs: Binding<Bool>,
        secondaryToolbarHeight: Binding<CGFloat>
    ) {
        _searchText = searchText
        _showOnlineSongs  = showOnlineSongs
        _secondaryToolbarHeight = secondaryToolbarHeight
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
            LazyVGrid(columns: columns, spacing: interItemPadding) {
                ForEach(albums) { album in
                    AlbumGridItemView(album: album)
                }
            }
            .padding([.top, .bottom], verticalPadding)
            .padding([.leading, .trailing], horizontalPadding)
        }
        .background(.background)
        .safeAreaPadding([.top], secondaryToolbarHeight)
    }
}
