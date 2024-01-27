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
    @State var syncController = SyncController(poll: true)
    #if os(macOS)
    let controlsToolbarPlacement = ToolbarItemPlacement.principal
    #else
    let controlsToolbarPlacement = ToolbarItemPlacement.bottomBar
    #endif

    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection)
                .toolbar {
                    ToolbarItemGroup {
                        Button(action: {
                            Task {
                                await syncController.sync()
                            }
                        }) {
                            Label("Sync", systemImage: "arrow.triangle.2.circlepath.circle")
                        }
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
                }
        } detail: {
            NavigationStack(path: $path) {
                DetailColumn(selection: $selection)
            }
            .toolbar {
                ToolbarItemGroup(placement: controlsToolbarPlacement) {
                    ShuffleButton()
                    ChangeSongButton(buttonChangeType: .previous)
                    PlayButton()
                    ChangeSongButton(buttonChangeType: .next)
                    RepeatButton()
                }
                ToolbarItemGroup(placement: controlsToolbarPlacement) {
                    PlayerCurrentSongView()
                    PlayerScrubberView()
                }
                ToolbarItem(placement: .automatic) {
                    QueueButton()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
