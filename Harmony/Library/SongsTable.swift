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
    @Binding var selection: Set<Song.ID>
    @State private var sortOrder = [KeyPathComparator(\Song.title, order: .reverse)]
    @State private var searchText = ""
    @State private var sortedSongs: [Song] = []

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
    private let isCompact = false
    #endif

    var body: some View {
        Table(sortedSongs, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title) { song in
                titleItem(song: song)
            }
            TableColumn("Album", value: \.album)
            TableColumn("Artist", value: \.artist)
            TableColumn("Genre", value: \.genre)
        }
        .contextMenu(forSelectionType: Song.ID.self) { items in
            contextMenuItemsForSongs(ids: items)
        } primaryAction: { ids in
            playSongsFromIds(ids)
        }
        .onAppear { sortedSongs = songs }
        .onChange(of: sortOrder) { // HACK: This is very slow.
            // When it is possible to sort the query directly, do that.
            Task.detached(priority: .userInitiated) {
                sortedSongs = songs.sorted(using: sortOrder)
            }
        }
        .searchable(text: $searchText)
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
    private func contextMenuItemsForSongs(ids: Set<Song.ID>) -> some View {
        if let songId = ids.first {
            contextMenuItemsForSong(id: songId)
        }
    }

    @ViewBuilder
    private func contextMenuItemsForSong(id: Song.ID) -> some View {
        if let dbObject = songs.filter({ $0.id == id }).first {
            SongContextMenuItems(song: dbObject)
        }
    }

    @MainActor private func playSongsFromIds(_ ids: Set<Song.ID>) {
        for id in ids {
            guard let dbObject = songs.filter({ $0.id == id }).first else {
                Logger.songsTable.error("Could not find song with id")
                return
            }
            PlayerController.shared.playSong(dbObject, withinSongs: songs.lazy)
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
