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
    @ObservedResults(DatabaseSong.self) var songs
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
        .contextMenu(forSelectionType: DatabaseSong.ID.self) { items in
            // TODO
        } primaryAction: { ids in
            for id in ids {
                Task { @MainActor in
                    guard let dbObject = songs.filter({ $0.id == id }).first else {
                        Logger.songsTable.error("Could not find song with id: \(id)")
                        return
                    }
                    guard let song = await dbObject.toSong() else {
                        Logger.songsTable.error("Could not convert dbsong with id: \(id)")
                        return
                    }
                    guard let songIdx = songs.firstIndex(of: dbObject) else {
                        Logger.songsTable.error("Could not find index of song with id: \(id)")
                        return
                    }
                    let nextIdx = songs.index(after: songIdx)

                    var futureSongs: [Song] = []
                    for i in (nextIdx...songs.count - 1) {
                        let futureDbObject = songs[i]
                        guard let futureSong = await futureDbObject.toSong() else {
                            Logger.songsTable.error("Could not convert future song of id: \(id)")
                            continue
                        }
                        futureSongs.append(futureSong)
                    }
                    PlayerController.shared.playSong(song, withFutureSongs: futureSongs)
                }
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
