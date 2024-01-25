//
//  ContentView.swift
//  Harmony
//
//  Created by Claudio Cambra on 7/1/24.
//

import HarmonyKit
import SwiftUI

struct ContentView: View {
    @State private var selection: Panel? = Panel.songs
    @State private var path = NavigationPath()
    @State private var settingsSheetVisible = false

    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection)
                .toolbar {
                    #if !os(macOS)
                    Button(action: {
                        settingsSheetVisible.toggle()
                    }) {
                        Label("Settings", systemImage: "gear")
                    }
                    .sheet(isPresented: $settingsSheetVisible) {
                        SettingsSheet()
                    }
                    #endif
                }
        } detail: {
            NavigationStack(path: $path) {
                DetailColumn(selection: $selection)
            }
        }
    }
}

#Preview {
    ContentView()
}
