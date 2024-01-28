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
    @State private var queueVisible = false
    #if os(macOS)
    let buttonStackInToolbar = true
    let buttonStackPlacement = ToolbarItemPlacement.navigation
    let currentSongPlacement = ToolbarItemPlacement.principal
    #else
    let buttonStackInToolbar = UIDevice.current.userInterfaceIdiom != .phone
    let buttonStackPlacement = ToolbarItemPlacement.topBarLeading
    let currentSongPlacement = ToolbarItemPlacement.bottomBar
    #endif

    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection)
                .toolbar {
                    ToolbarItemGroup {
                        Button(action: {
                            Task {
                                await SyncController.shared.sync()
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
                if buttonStackInToolbar {
                    ToolbarItemGroup(placement: buttonStackPlacement) {
                        ShuffleButton()
                        ChangeSongButton(buttonChangeType: .previous)
                        PlayButton()
                        ChangeSongButton(buttonChangeType: .next)
                        RepeatButton()
                    }
                }
                ToolbarItem(placement: currentSongPlacement) {
                    ToolbarCurrentSongView()
                }
            }
        }
        .inspector(isPresented: $queueVisible) {
            PlayerQueueView()
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        QueueButton(queueVisible: $queueVisible)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
