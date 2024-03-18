//
//  ArtistsListView.swift
//  Harmony
//
//  Created by Claudio Cambra on 12/3/24.
//

import HarmonyKit
import SwiftData
import SwiftUI

struct ArtistsListView: View {
    @Query(sort: \Artist.name) var artists: [Artist]
    @Binding var searchText: String
    @Binding var selection: Artist?
    @Binding var showOnlineSongs: Bool

    init(
        searchText: Binding<String>,
        selection: Binding<Artist?>,
        showOnlineSongs: Binding<Bool>
    ) {
        _searchText = searchText
        _selection = selection
        _showOnlineSongs = showOnlineSongs
        let searchTextVal = searchText.wrappedValue
        let showOnlineSongsVal = showOnlineSongs.wrappedValue
        let downloadedState = DownloadState.downloaded.rawValue
        let outdatedDownloadedState = DownloadState.downloadedOutdated.rawValue
        var predicate: Predicate<Artist>
        if searchTextVal.isEmpty, showOnlineSongsVal {
            predicate = #Predicate<Artist> { !$0.songs.isEmpty }
        } else if !searchTextVal.isEmpty, showOnlineSongsVal {
            predicate = #Predicate<Artist> { $0.name.localizedStandardContains(searchTextVal) }
        } else if searchTextVal.isEmpty, !showOnlineSongsVal {
            predicate = #Predicate<Artist> {
                $0.songs.contains(where: {
                    $0.downloadState == downloadedState ||
                    $0.downloadState == outdatedDownloadedState
                })
            }
        } else {
            predicate = #Predicate<Artist> {
                $0.name.localizedStandardContains(searchTextVal) &&
                $0.songs.contains(where: {
                    $0.downloadState == downloadedState ||
                    $0.downloadState == outdatedDownloadedState
                })
            }
        }
        _artists = Query(filter: predicate, sort: \Artist.name)
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(artists) { artist in
                NavigationLink(value: artist) {
                    Text(artist.name)
                }
            }
        }
        .listStyle(.plain)
        #if !os(macOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer)
        #endif
    }
}
