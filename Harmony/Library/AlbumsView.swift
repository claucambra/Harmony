//
//  AlbumsView.swift
//  Harmony
//
//  Created by Claudio Cambra on 12/3/24.
//

import HarmonyKit
import SwiftData
import SwiftUI

struct AlbumsView: View {
    @Query(sort: \Album.title) var albums: [Album]
    @Binding var searchText: String
    @Binding var showOnlineSongs: Bool
    @Binding var sortOrder: SortDescriptor<Album>

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
        AlbumsGridView(
            albums: albums,
            searchText: $searchText,
            showOnlineSongs: $showOnlineSongs,
            sortOrder: $sortOrder
        )
    }
}
