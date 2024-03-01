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
    @State var albumDetailVisible = false
    @State var detailAlbum: Album?

    #if os(macOS)
    let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 300), spacing: UIMeasurements.largePadding)
    ]
    let horizontalPadding = UIMeasurements.ultraLargePadding
    #else
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 240), spacing: UIMeasurements.largePadding)
    ]
    let horizontalPadding = UIMeasurements.largePadding
    #endif
    let verticalPadding = UIMeasurements.largePadding
    let interItemPadding = UIMeasurements.largePadding

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
            #if os(macOS)
            Text("Albums")
                .font(.title)
                .bold()
                .padding(verticalPadding)
            #endif
            LazyVGrid(columns: columns, spacing: interItemPadding) {
                ForEach(albums) { album in
                    AlbumGridItemView(album: album)
                        .onTapGesture {
                            detailAlbum = album
                            albumDetailVisible = true
                        }
                }
            }
            #if os(macOS)
            .padding([.bottom], verticalPadding)
            #else
            .padding([.top, .bottom], verticalPadding)
            #endif
            .padding([.leading, .trailing], horizontalPadding)
            .navigationDestination(isPresented: $albumDetailVisible) {
                if let detailAlbum = detailAlbum {
                    let title = detailAlbum.title.isEmpty ? "Unknown album" : detailAlbum.title
                    AlbumDetailView(album: detailAlbum)
                }
            }
        }
        .background(.background)
    }
}
