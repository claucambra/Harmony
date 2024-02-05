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
    #if os(macOS)
    @State private var queueVisible = false
    let buttonStackInToolbar = true
    let buttonStackPlacement = ToolbarItemPlacement.navigation
    let currentSongPlacement = ToolbarItemPlacement.principal
    let volumeSliderPlacement = ToolbarItemPlacement.destructiveAction
    let displayVolumeSlider = true
    #else
    @State private var queueVisible = UIDevice.current.userInterfaceIdiom == .phone
    let buttonStackInToolbar = UIDevice.current.userInterfaceIdiom != .phone
    let buttonStackPlacement = ToolbarItemPlacement.topBarLeading
    let volumeSliderPlacement = ToolbarItemPlacement.topBarTrailing
    let displayVolumeSlider = false
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

                #if os(macOS)
                ToolbarItem(placement: currentSongPlacement) {
                    ToolbarCurrentSongView()
                }
                #endif

                if displayVolumeSlider {
                    ToolbarItemGroup(placement: volumeSliderPlacement) {
                        Spacer()
                        ToolbarVolumeSliderView()
                    }
                }

                #if !os(macOS)
                if UIDevice.current.userInterfaceIdiom != .phone {
                    inspectorToolbarItem
                }
                #endif
            }
        }
        .inspector(isPresented: $queueVisible) {
            #if os(macOS)
            rightSidebarQueue
            #else
            if UIDevice.current.userInterfaceIdiom == .phone {
                VStack {
                    PlayerQueueView()
                }
                .interactiveDismissDisabled()
            } else {
                rightSidebarQueue.navigationTitle("Queue")
            }
            #endif
        }
    }

    @ViewBuilder
    var rightSidebarQueue: some View {
        PlayerQueueView()
            .inspectorColumnWidth(320) // Fix visual issues with inspector toggle and search b.
            .toolbar {
                #if os(macOS)
                inspectorToolbarItem
                #endif
            }
    }

    @ToolbarContentBuilder
    var inspectorToolbarItem: some ToolbarContent {
        ToolbarItem {
            QueueButton(queueVisible: $queueVisible)
        }
    }
}

#Preview {
    ContentView()
}
