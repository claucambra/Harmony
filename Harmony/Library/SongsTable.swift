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
            TableColumn("Song", value: \.title)
        } rows: {
            Section {
                ForEach(model.songs) { song in
                    TableRow(song)
                }
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
