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
    @State private var sortOrder = [KeyPathComparator(\DatabaseSong.title, order: .reverse)]
    @Binding var selection: Set<DatabaseSong.ID>
    @State var searchText: String = ""
    @State var searchTimer: Timer?
    let searchInterval = 0.5

    var body: some View {
        Table(selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title)
            TableColumn("Album", value: \.album)
            TableColumn("Artist", value: \.artist)
            TableColumn("Genre", value: \.genre)
        } rows: {
            ForEach(songs) { song in
                TableRow(song)
            }
        }
        .onChange(of: sortOrder, { oldValue, newValue in
            guard let sortDescriptor = newValue.first else { return }
            let keyPath = sortDescriptor.keyPath
            let ascending = sortDescriptor.order == .reverse
            $songs.sortDescriptor = SortDescriptor(keyPath: keyPath, ascending: ascending)
        })
        .contextMenu(forSelectionType: DatabaseSong.ID.self) { items in
            // TODO
        } primaryAction: { ids in
            // TODO: This shouldn't be handled here
            for id in ids {
                guard let dbObject = songs.filter({ $0.id == id }).first else {
                    Logger.songsTable.error("Could not find song with id: \(id)")
                    return
                }
                PlayerController.shared.playSong(dbObject, withinSongs: songs)
            }
        }
        .searchable(text: $searchText) {
            if searchText != "", searchTimer == nil {
                ForEach(songs) { filteredSong in
                    Text(filteredSong.title).searchCompletion(filteredSong.title)
                }
            }
        }
        .onChange(of: searchText) {
            guard searchText != "" else {
                killTimer()
                searchTimer = Timer.scheduledTimer(
                    withTimeInterval: searchInterval, repeats: false
                ) { _ in
                    $songs.filter = nil
                }
                return
            }

            killTimer()
            searchTimer = Timer.scheduledTimer(
                withTimeInterval: searchInterval, repeats: false
            ) { _ in
                #if DEBUG
                // Force some type safety here for a reminder in case things change later
                _ = \DatabaseSong.title
                #endif
                // When possible, change this to use the `where` property using the type-safe API
                // We need to manually filter because we can't pick the case sensitibity or CONTAINS
                // when using searchable on the collection directly
                $songs.filter = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
                searchTimer = nil
            }
        }
    }

    private func killTimer() {
        searchTimer?.invalidate()
        searchTimer = nil
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
