//
//  ArtistsListView.swift
//  Harmony
//
//  Created by Claudio Cambra on 12/3/24.
//

import HarmonyKit
import SwiftData
import SwiftUI

struct ArtistsListView: View {
    @Query(sort: \Artist.name) var artists: [Artist]
    @Binding var selection: Artist?

    var body: some View {
        List(selection: $selection) {
            ForEach(artists) { artist in
                NavigationLink(value: artist) {
                    Text(artist.name)
                }
            }
        }
        .listStyle(.plain)
    }
}
