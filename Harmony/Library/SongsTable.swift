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
    @Query var songs: [DatabaseSong]
    @Binding var selection: Set<DatabaseSong.ID>
    @State private var sortOrder = [KeyPathComparator(\DatabaseSong.title, order: .reverse)]
    @State private var searchText = ""

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
        }
        .contextMenu(forSelectionType: DatabaseSong.ID.self) { items in
            contextMenuItemsForSongs(ids: items)
        } primaryAction: { ids in
            playSongsFromIds(ids)
        }
        .onChange(of: sortOrder, { oldValue, newValue in
            guard let sortDescriptor = newValue.first else { return }
            let keyPath = sortDescriptor.keyPath
            let ascending = sortDescriptor.order == .reverse
            //$songs.sortDescriptor = SortDescriptor(keyPath: keyPath, ascending: ascending)
        })
        .searchable(text: $searchText)
    }

    @ViewBuilder
    private func titleItem(song: DatabaseSong) -> some View {
        if isCompact {
            SongListItemView(song: song, isCurrentSong: false)
        } else {
            Text(song.title)
        }
    }

    @ViewBuilder
    private func contextMenuItemsForSongs(ids: Set<DatabaseSong.ID>) -> some View {
        if let songId = ids.first {
            contextMenuItemsForSong(id: songId)
        }
    }

    @ViewBuilder
    private func contextMenuItemsForSong(id: DatabaseSong.ID) -> some View {
        if let dbObject = songs.filter({ $0.id == id }).first {
            SongContextMenuItems(song: dbObject)
        }
    }

    @MainActor private func playSongsFromIds(_ ids: Set<DatabaseSong.ID>) {
        for id in ids {
            guard let dbObject = songs.filter({ $0.id == id }).first else {
                Logger.songsTable.error("Could not find song with id")
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
