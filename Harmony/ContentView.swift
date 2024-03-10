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
        mainView
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
            #if os(macOS)
            .searchable(text: $searchText, placement: searchablePlacement)
            #endif
            .toolbar {
                ControlsToolbar(queueVisible: $queueVisible)
            }
            .environment(\.floatingBarHeight, floatingBarHeight)
    }

    @ViewBuilder
    private var mainView: some View {
        #if os(macOS)
        splitView
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            splitView
        } else {
            TabContentView(
                path: $path,
                queueVisible: $queueVisible,
                searchText: $searchText,
                selection: $selection,
                showOnlineSongs: $showOnlineSongs
            )
        }
        #endif
    }

    @ViewBuilder
    private var splitView: some View {
        SplitContentView(
            path: $path,
            searchText: $searchText,
            selection: $selection,
            showOnlineSongs: $showOnlineSongs
        )
    }

    @ViewBuilder
    private var rightSidebarQueue: some View {
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
