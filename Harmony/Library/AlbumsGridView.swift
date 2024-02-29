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
    @Query(sort: \Album.title) var albums: [Album]
    @Binding var searchText: String
    @Binding var showOnlineSongs: Bool
    @State var selection: Set<Album.ID> = []
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(albums) { album in
                    AlbumGridItemView(album: album)
                }
            }
        }
    }
}
