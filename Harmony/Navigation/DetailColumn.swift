//
//  DetailColumn.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import HarmonyKit
import SwiftUI

struct DetailColumn: View {
    @Binding var selection: Panel?
    @Binding var searchText: String

    var body: some View {
        switch selection ?? .songs {
        case .songs:
            SongsTable(searchText: $searchText)
                .navigationTitle("Songs")
        }
    }
}

struct DetailColumn_Previews: PreviewProvider {
    struct Preview: View {
        @State private var selection: Panel? = .songs
        @State private var searchText = "Search text"

        var body: some View {
            DetailColumn(selection: $selection, searchText: $searchText)
        }
    }
    static var previews: some View {
        Preview()
    }
}
