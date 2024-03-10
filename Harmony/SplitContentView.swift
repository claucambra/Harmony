//
//  SplitContentView.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/3/24.
//

import SwiftUI

struct SplitContentView: View {
    @Binding var path: NavigationPath
    @Binding var searchText: String
    @Binding var selection: Panel?
    @Binding var showOnlineSongs: Bool
    @Environment(\.floatingBarHeight) var floatingBarHeight: CGFloat
    @State var settingsSheetVisible: Bool = false

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
        }
    }
}
