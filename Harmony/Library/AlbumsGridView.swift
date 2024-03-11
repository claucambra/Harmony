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
    @Binding var sortOrder: SortDescriptor<Album>

    @State private var albumDetailVisible = false
    @State private var detailAlbum: Album?
    @State private var selection: Set<Album.ID> = []

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

    init(
        searchText: Binding<String>,
        showOnlineSongs: Binding<Bool>,
        sortOrder: Binding<SortDescriptor<Album>>
    ) {
        _searchText = searchText
        _showOnlineSongs = showOnlineSongs
        _sortOrder = sortOrder
        let searchTextVal = searchText.wrappedValue
        let showOnlineSongsVal = showOnlineSongs.wrappedValue
        let sortOrderVal = sortOrder.wrappedValue
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
        _albums = Query(filter: predicate, sort: [sortOrderVal])
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
            .toolbar {
                ToolbarItem {
                    Menu {
                        Toggle(isOn: $showOnlineSongs) {
                            Label("Undownloaded songs", systemImage: "cloud")
                        }
                    } label: {
                        Label("Sort and filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .background(.background)
    }
}
