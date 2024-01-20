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
    }
}
