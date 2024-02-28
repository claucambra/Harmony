//
//  Sidebar.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import SwiftUI

enum Panel {
    case songs, albums
}

struct Sidebar: View {
    @Binding var selection: Panel?
    @Binding var showOnlineSongs: Bool

    var body: some View {
        List(selection: $selection) {
            Section("Library") {
                NavigationLink(value: Panel.songs) {
                    Label("Songs", systemImage: "music.note")
                }
                NavigationLink(value: Panel.albums) {
                    Label("Albums", systemImage: "rectangle.stack")
                }
            }
            Section("Filters") {
                Toggle(isOn: $showOnlineSongs) {
                    Label("Undownloaded songs", systemImage: "cloud")
                }
            }
        }
        .navigationTitle("Library")
    }
}

struct Sidebar_Previews: PreviewProvider {
    struct Preview: View {
        @State private var selection: Panel? = Panel.songs
        @State private var showOnlineSongs = true
        var body: some View {
            Sidebar(selection: $selection, showOnlineSongs: $showOnlineSongs)
        }
    }

    static var previews: some View {
        NavigationSplitView {
            Preview()
        } detail: {
           Text("Detail!")
        }
    }
}

