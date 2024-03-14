//
//  SplitContentView.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/3/24.
//

import HarmonyKit
import SwiftUI

struct SplitContentView: View {
    @Binding var path: NavigationPath
    @Binding var searchText: String
    @Binding var selection: Panel?
    @Binding var showOnlineSongs: Bool
    @Binding var albumSort: SortDescriptor<Album>
    @Environment(\.floatingBarHeight) var floatingBarHeight: CGFloat
    @ObservedObject var syncController = SyncController.shared
    @State var artistSelection: Artist?
    @State var columnVisibility = NavigationSplitViewVisibility.all
    @State var settingsSheetVisible: Bool = false

    var body: some View {
        #if os(macOS)
        twoColumnView
        #else
        if selection == .artists {
            threeColumnView
        } else {
            twoColumnView
        }
        #endif
    }

    @ViewBuilder
    private var twoColumnView: some View {
        NavigationSplitView {
            navSideBar
        } detail: {
            NavigationStack(path: $path) {
                DetailColumn(
                    selection: $selection,
                    searchText: $searchText,
                    showOnlineSongs: $showOnlineSongs,
                    albumSort: $albumSort
                )
            }
            .safeAreaPadding([.bottom], floatingBarHeight)
        }
    }

    @ViewBuilder
    private var threeColumnView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            navSideBar
        } content: {
            ArtistsListView(selection: $artistSelection)
                .navigationTitle("Artists")
                .safeAreaPadding([.bottom], floatingBarHeight)
        } detail: {
            NavigationStack(path: $path) {
                if let artist = artistSelection {
                    AlbumsListView(
                        albums: artist.albums,
                        searchText: $searchText,
                        showOnlineSongs: $showOnlineSongs,
                        sortOrder: $albumSort
                    )
                }
            }
            .safeAreaPadding([.bottom], floatingBarHeight)
        }
    }

    @ViewBuilder
    private var navSideBar: some View {
        Sidebar(selection: $selection, showOnlineSongs: $showOnlineSongs)
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        Task {
                            await syncController.sync()
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.circle")
                    }
                    .disabled(syncController.currentlySyncingFully)
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
    }
}
