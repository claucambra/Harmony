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
    @Environment(\.modelContext) private var modelContext

    @State var songs: [Song] = []
    @Binding var searchText: String
    @Binding var showOnlineSongs: Bool
    @State var selection: Set<Song.ID> = []
    @State private var sortOrder = [KeyPathComparator(\Song.title)]
    @State private var songsFetcher: ItemFetcher<Song>?

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
    private let isCompact = false
    #endif

    var body: some View {
        Table(songs, selection: $selection, sortOrder: $sortOrder) {
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
        .task { await loadSongs() }
        .onChange(of: sortOrder) { Task { await loadSongs() } }
        .onChange(of: showOnlineSongs) { Task { await loadSongs() } }
        #if !os(macOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer)
        .toolbar {
            if UIDevice.current.userInterfaceIdiom == .phone {
                ToolbarItem {
                    Menu {
                        Toggle(isOn: $showOnlineSongs) {
                            Label("Undownloaded songs", systemImage: "cloud")
                        }
                        Button("Title") { sortOrder = [KeyPathComparator(\Song.title)] }
                        Button("Album") { sortOrder = [KeyPathComparator(\Song.album)] }
                        Button("Artist") { sortOrder = [KeyPathComparator(\Song.artist)] }
                        Button("Year") { sortOrder = [KeyPathComparator(\Song.year)] }
                    } label: {
                        Label("Sort and filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
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

    private func loadSongs() async {
        if songsFetcher == nil {
            songsFetcher = ItemFetcher<Song>(modelContainer: modelContext.container)
        }

        let searchTextVal = $searchText.wrappedValue
        let showOnlineSongsVal = $showOnlineSongs.wrappedValue
        let downloadedState = DownloadState.downloaded.rawValue
        let outdatedDownloadedState = DownloadState.downloadedOutdated.rawValue
        var initialPredicate: Predicate<Song>
        if searchTextVal.isEmpty, showOnlineSongsVal {
            initialPredicate = #Predicate<Song> { !$0.identifier.isEmpty }
        } else if !searchTextVal.isEmpty, showOnlineSongsVal {
            initialPredicate = #Predicate<Song> { $0.title.localizedStandardContains(searchTextVal) }
        } else if searchTextVal.isEmpty, !showOnlineSongsVal {
            initialPredicate = #Predicate<Song> {
                $0.downloadState == downloadedState ||
                $0.downloadState == outdatedDownloadedState
            }
        } else {
            initialPredicate = #Predicate<Song> {
                $0.title.localizedStandardContains(searchTextVal)
                && ($0.downloadState == downloadedState ||
                    $0.downloadState == outdatedDownloadedState)
            }
        }

        let songIds = try! await songsFetcher?.getItems(predicate: initialPredicate) ?? []
        let predicate = #Predicate<Song> { songIds.contains($0.persistentModelID) }
        let descriptor = FetchDescriptor<Song>(predicate: predicate)
        let fetchedItems = try! modelContext.fetch(descriptor)
        songs = fetchedItems.sorted(using: sortOrder)
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
