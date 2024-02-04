//
//  SongsTable.swift
//  Harmony
//
//  Created by Claudio Cambra on 19/1/24.
//

import HarmonyKit
import OSLog
import RealmSwift
import SwiftUI

struct SongsTable: View {
    @ObservedResults(
        DatabaseSong.self,
        sortDescriptor: SortDescriptor(keyPath: \DatabaseSong.title)
    ) var songs
    @Environment(\.searchText) var searchText
    @Environment(\.isSearching) private var isSearching
    @Binding var selection: Set<DatabaseSong.ID>
    @State private var sortOrder = [KeyPathComparator(\DatabaseSong.title, order: .reverse)]
    @State private var searchTimer: Timer?
    let searchInterval = 0.5

    var body: some View {
        // HACK: For some reason, the table view really likes to re-render every single time a
        // searchable in the hierarchy is interacted with. With the songs table this obviously
        // leads to massive slowdowns and brings the UI to its knees.
        //
        // In order to work around this behaviour, we remove the table view while search is ongoing.
        if searchTimer == nil {
            table
        } else {
            loadingView
        }
    }

    @ViewBuilder
    private var table: some View {
        Table(songs, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title)
            TableColumn("Album", value: \.album)
            TableColumn("Artist", value: \.artist)
            TableColumn("Genre", value: \.genre)
        }
        .contextMenu(forSelectionType: DatabaseSong.ID.self) { items in
            // TODO
        } primaryAction: { ids in
            playSongsFromIds(ids)
        }
        .onChange(of: sortOrder, { oldValue, newValue in
            guard let sortDescriptor = newValue.first else { return }
            let keyPath = sortDescriptor.keyPath
            let ascending = sortDescriptor.order == .reverse
            $songs.sortDescriptor = SortDescriptor(keyPath: keyPath, ascending: ascending)
        })
        .onChange(of: searchText) { startSearchTimer() }
    }

    @ViewBuilder
    private var loadingView: some View {
        Text("Loading...")
            .onChange(of: searchText) { startSearchTimer() }
    }

    private func startSearchTimer() {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(
            withTimeInterval: searchInterval, repeats: false
        ) { _ in
            #if DEBUG
            // Force some type safety here for a reminder in case things change later
            _ = \DatabaseSong.title
            #endif
            guard searchText != "" else {
                $songs.filter = nil
                searchTimer = nil
                return
            }
            // When possible, change this to use the `where` property using the type-safe API
            // We need to manually filter because we can't pick the case sensitibity or CONTAINS
            // when using searchable on the collection directly
            $songs.filter = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
            searchTimer = nil
        }
    }

    private func playSongsFromIds(_ ids: Set<DatabaseSong.ID>) {
        for id in ids {
            guard let dbObject = songs.filter({ $0.id == id }).first else {
                Logger.songsTable.error("Could not find song with id: \(id)")
                return
            }
            PlayerController.shared.playSong(dbObject, withinSongs: songs)
        }
    }
}

struct SongsTable_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            SongsTable(selection: .constant([]))
        }
    }

    static var previews: some View {
        Preview()
    }
}
