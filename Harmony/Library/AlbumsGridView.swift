//
//  AlbumsGridView.swift
//  Harmony
//
//  Created by Claudio Cambra on 28/2/24.
//

import HarmonyKit
import SwiftData
import SwiftUI

struct AlbumsGridView: View {
    @Query(sort: \Song.title) var songs: [Song]
    @Binding var searchText: String
    @Binding var showOnlineSongs: Bool
    @State var selection: Set<Song.ID> = []
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(songs) { song in
                    Rectangle().foregroundColor(.orange).frame(height: 25)
                }
            }
        }
    }
}
