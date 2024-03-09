//
//  SongsTable.swift
//  Harmony
//
//  Created by Claudio Cambra on 19/1/24.
//

import HarmonyKit
import OSLog
import SwiftData
import SwiftUI

struct SongsTable: View {
    @Query(sort: \Song.title) var songs: [Song]
    @Binding var searchText: String
    @Binding var showOnlineSongs: Bool
    @State var selection: Set<Song.ID> = []
    @State private var sortOrder = [KeyPathComparator(\Song.title, order: .reverse)]
    @State private var sortedSongs: [Song] = []

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
    private let isCompact = false
    #endif

    init(searchText: Binding<String>, showOnlineSongs: Binding<Bool>) {
        _searchText = searchText
        _showOnlineSongs  = showOnlineSongs
        let searchTextVal = searchText.wrappedValue
        let showOnlineSongsVal = showOnlineSongs.wrappedValue
        let downloadedState = DownloadState.downloaded.rawValue
        let outdatedDownloadedState = DownloadState.downloadedOutdated.rawValue
        var predicate: Predicate<Song>
        if searchTextVal.isEmpty, showOnlineSongsVal {
            predicate = #Predicate<Song> { !$0.identifier.isEmpty }
        } else if !searchTextVal.isEmpty, showOnlineSongsVal {
            predicate = #Predicate<Song> { $0.title.localizedStandardContains(searchTextVal) }
        } else if searchTextVal.isEmpty, !showOnlineSongsVal {
            predicate = #Predicate<Song> {
                $0.downloadState == downloadedState ||
                $0.downloadState == outdatedDownloadedState
            }
        } else {
            predicate = #Predicate<Song> {
                $0.title.localizedStandardContains(searchTextVal)
                && ($0.downloadState == downloadedState ||
                    $0.downloadState == outdatedDownloadedState)
            }
        }
        _songs = Query(filter: predicate, sort: \Song.title)
    }

    var body: some View {
        Table(sortedSongs, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title) { song in
                titleItem(song: song)
            }
            TableColumn("Album", value: \.album)
            TableColumn("Artist", value: \.artist)
            TableColumn("Genre", value: \.genre)
            TableColumn("State") { song in
                availableOfflineView(song: song)
            }
            .width(UIMeasurements.tableColumnMiniWidth)
            TableColumn("Playing") { song in
                CurrentlyPlayingSongIndicatorView(song: song)
            }
            .width(UIMeasurements.tableColumnMiniWidth)
        }
        .contextMenu(forSelectionType: Song.ID.self) { items in
            contextMenuItemsForSongs(ids: items, songs: songs)
        } primaryAction: { ids in
            playSongsFromIds(ids, songs: songs)
        }
        .onAppear { sortedSongs = songs }
        .onChange(of: songs) { sortedSongs = songs }
        .onChange(of: sortOrder) { // HACK: This is very slow.
            // When it is possible to sort the query directly, do that.
            Task.detached(priority: .userInitiated) {
                sortedSongs = songs.sorted(using: sortOrder)
            }
        }
        #if !os(macOS)
        .searchable(text: $searchText)
        #endif
    }

    @ViewBuilder
    private func titleItem(song: Song) -> some View {
        if isCompact {
            SongListItemView(song: song, isCurrentSong: false)
        } else {
            Text(song.title)
        }
    }

    @ViewBuilder
    private func availableOfflineView(song: Song) -> some View {
        if song.downloadState == DownloadState.downloaded.rawValue ||
            song.downloadState == DownloadState.downloadedOutdated.rawValue {
            Label("Available offline", systemImage: "arrow.down.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(.tertiary)
        } else {
            Label("Streamable song", systemImage: "cloud")
                .labelStyle(.iconOnly)
                .foregroundStyle(.tertiary)
        }
    }
}

struct SongsTable_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            SongsTable(searchText: .constant("Search text"), showOnlineSongs: .constant(true))
        }
    }

    static var previews: some View {
        Preview()
    }
}
