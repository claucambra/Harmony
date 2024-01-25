//
//  Sidebar.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import SwiftUI

enum Panel {
    case songs
}

struct Sidebar: View {
    @Binding var selection: Panel?

    var body: some View {
        List(selection: $selection) {
            Section("Library") {
                NavigationLink(value: Panel.songs) {
                    Label("Songs", systemImage: "music.note")
                }
            }
        }
        .navigationTitle("Library")
    }
}

struct Sidebar_Previews: PreviewProvider {
    struct Preview: View {
        @State private var selection: Panel? = Panel.songs
        var body: some View {
            Sidebar(selection: $selection)
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

