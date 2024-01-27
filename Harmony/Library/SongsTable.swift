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
            for id in ids {
                guard let dbObject = songs.filter({ $0.id == id }).first else {
                    Logger.songsTable.error("Could not find song with id: \(id)")
                    return
                }
                PlayerController.shared.playSong(dbObject, withinSongs: songs)
            }
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
