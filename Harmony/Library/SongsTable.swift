//
//  SongsTable.swift
//  Harmony
//
//  Created by Claudio Cambra on 19/1/24.
//

import HarmonyKit
import SwiftUI

struct SongsTable: View {
    @ObservedObject var model: SongsModel
    @State private var sortOrder = [KeyPathComparator(\Song.title, order: .reverse)]
    @Binding var selection: Set<Song.ID>

    var body: some View {
        Table(selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title)
            TableColumn("Album", value: \.album)
            TableColumn("Artist", value: \.artist)
            TableColumn("Genre", value: \.genre)
        } rows: {
            ForEach(model.songs) { song in
                TableRow(song)
            }
        }
        .contextMenu(forSelectionType: Song.ID.self) { items in
            // TODO
        } primaryAction: { items in
            for item in items {
                guard let song = model.songs.first(where: { song in
                    return song.id == item
                }) else { continue }
                PlayerController.shared.playSong(song)
            }
        }
    }
}

struct SongsTable_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject private var model = SongsModel(withBackends: BackendsModel.shared.backends)

        var body: some View {
            SongsTable(
                model: model,
                selection: .constant([])
            )
        }
    }

    static var previews: some View {
        Preview()
    }
}
