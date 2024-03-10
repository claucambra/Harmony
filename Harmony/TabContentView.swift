//
//  TabContentView.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/3/24.
//

import SwiftUI

struct TabContentView: View {
    @Binding var path: NavigationPath
    @Binding var searchText: String
    @Binding var selection: Panel?
    @Binding var settingsSheetVisible: Bool
    @Binding var showOnlineSongs: Bool
    @Environment(\.floatingBarHeight) var floatingBarHeight: CGFloat

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack(path: $path) {
                SongsTable(searchText: $searchText, showOnlineSongs: $showOnlineSongs)
                    .navigationTitle("Songs")
            }
            .tabItem { Label("Songs", systemImage: "music.note") }
            .tag(Panel.songs)

            NavigationStack(path: $path) {
                AlbumsGridView(searchText: $searchText, showOnlineSongs: $showOnlineSongs)
                    .navigationTitle("Albums")
            }
            .tabItem { Label("Albums", systemImage: "rectangle.stack") }
            .tag(Panel.albums)
        }
    }
}
