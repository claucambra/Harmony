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
    @Environment(\.floatingBarHeight) var floatingBarHeight
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
        let downloadedState = DownloadState.downloaded.rawValue
        let outdatedDownloadedState = DownloadState.downloadedOutdated.rawValue
        var predicate: Predicate<Album>
        if searchTextVal.isEmpty, showOnlineSongsVal {
            predicate = #Predicate<Album> { !$0.songs.isEmpty }
        } else if !searchTextVal.isEmpty, showOnlineSongsVal {
            predicate = #Predicate<Album> { $0.title.localizedStandardContains(searchTextVal) }
        } else if searchTextVal.isEmpty, !showOnlineSongsVal {
            predicate = #Predicate<Album> {
                $0.songs.contains(where: {
                    $0.downloadState == downloadedState ||
                    $0.downloadState == outdatedDownloadedState
                })
            }
        } else {
            predicate = #Predicate<Album> {
                $0.title.localizedStandardContains(searchTextVal) &&
                $0.songs.contains(where: {
                    $0.downloadState == downloadedState ||
                    $0.downloadState == outdatedDownloadedState
                })
            }
        }
        _albums = Query(filter: predicate, sort: \Album.title)
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
                    AlbumDetailView(album: detailAlbum)
                        #if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
                        .safeAreaPadding([.bottom], floatingBarHeight)
                        #endif
                }
            }
        }
        .background(.background)
    }
}
