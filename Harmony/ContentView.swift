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
    @State private var showOnlineSongs = true
    @State private var floatingBarHeight = 0.0
    #if os(macOS)
    let searchablePlacement = SearchFieldPlacement.sidebar
    #else
    let searchablePlacement = SearchFieldPlacement.automatic
    #endif

    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection, showOnlineSongs: $showOnlineSongs)
                .toolbar {
                    ToolbarItemGroup {
                        Button {
                            Task {
                                await SyncController.shared.sync()
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.circle")
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
                .safeAreaPadding([.bottom], floatingBarHeight)
        } detail: {
            NavigationStack(path: $path) {
                DetailColumn(
                    selection: $selection, 
                    searchText: $searchText,
                    showOnlineSongs: $showOnlineSongs
                )
            }
            .safeAreaPadding([.bottom], floatingBarHeight)
            .environment(\.floatingBarHeight, floatingBarHeight)
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
                    .safeAreaPadding([.leading, .trailing, .bottom], UIMeasurements.largePadding)
                    .frame(alignment: .bottom)
                    .background {
                        GeometryReader { proxy in
                            Rectangle()
                                .foregroundStyle(.clear)
                                .onAppear {
                                    let safeHeight = proxy.size.height + UIMeasurements.largePadding
                                    floatingBarHeight = safeHeight
                                }
                                .onChange(of: proxy.size) {
                                    let safeHeight = proxy.size.height + UIMeasurements.largePadding
                                    floatingBarHeight = safeHeight
                                }
                        }
                    }
                    .onTapGesture {
                        // Make sure to hide any keyboard currently on screen
                        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                        scene?.windows.filter {$0.isKeyWindow}.first?.endEditing(true)
                        queueVisible.toggle()
                    }
            }
            #endif
        }
        #if os(macOS)
        .searchable(text: $searchText, placement: searchablePlacement) // TODO: Re-add suggestions
        #endif
        .toolbar {
            ControlsToolbar(queueVisible: $queueVisible)
        }
    }

    @ViewBuilder
    var rightSidebarQueue: some View {
        PlayerQueueView()
            .toolbar {
                #if os(macOS)
                ToolbarItem {
                    QueueButton(queueVisible: $queueVisible)
                }
                #endif
            }
    }
}

#Preview {
    ContentView()
}
