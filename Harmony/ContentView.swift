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
    @State private var searchText = ""
    #if os(macOS)
    let buttonStackInToolbar = true
    let buttonStackPlacement = ToolbarItemPlacement.navigation
    let currentSongPlacement = ToolbarItemPlacement.principal
    let volumeSliderPlacement = ToolbarItemPlacement.destructiveAction
    let displayVolumeSlider = true
    let floatingBarSafeArea = 0.0
    let searchablePlacement = SearchFieldPlacement.sidebar
    #else
    let buttonStackInToolbar = UIDevice.current.userInterfaceIdiom != .phone
    let buttonStackPlacement = ToolbarItemPlacement.topBarLeading
    let volumeSliderPlacement = ToolbarItemPlacement.topBarTrailing
    let displayVolumeSlider = false
    let floatingBarSafeArea = UIDevice.current.userInterfaceIdiom == .phone ? 88.0 : 0.0 // TODO
    let searchablePlacement = SearchFieldPlacement.automatic
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
                .safeAreaPadding([.bottom], floatingBarSafeArea)
        } detail: {
            NavigationStack(path: $path) {
                DetailColumn(selection: $selection, searchText: $searchText)
            }
            .safeAreaPadding([.bottom], floatingBarSafeArea)
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
                PhonePlayerDrawer()
            } else {
                rightSidebarQueue.navigationTitle("Queue")
            }
            #endif
        }
        .overlay(alignment: .bottom) {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                FloatingCurrentSongView()
                    .safeAreaPadding([.leading, .trailing, .bottom], 10)
                    .frame(alignment: .bottom)
                    .onTapGesture {
                        queueVisible.toggle()
                    }
            }
            #endif
        }
        #if os(macOS)
        .searchable(text: $searchText, placement: searchablePlacement) // TODO: Re-add suggestions
        #endif
    }

    @ViewBuilder
    var rightSidebarQueue: some View {
        PlayerQueueView()
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
