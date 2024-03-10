//
//  TabContentView.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/3/24.
//

#if os(iOS)

import SwiftUI

struct TabContentView: View {
    @Binding var path: NavigationPath
    @Binding var queueVisible: Bool
    @Binding var searchText: String
    @Binding var selection: Panel?
    @Binding var showOnlineSongs: Bool
    @State private var floatingBarHeight: CGFloat = 0.0
    @State private var tabBarHeight: CGFloat = 0.0
    private let floatingBarPadding = UIMeasurements.mediumPadding
    private let floatingBarTotalPadding = UIMeasurements.mediumPadding * 2

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack(path: $path) {
                SongsTable(searchText: $searchText, showOnlineSongs: $showOnlineSongs)
                    .navigationTitle("Songs")
                    .safeAreaPadding(.bottom, floatingBarHeight + floatingBarTotalPadding)
            }
            .tabItem { Label("Songs", systemImage: "music.note") }
            .tag(Panel.songs)
            .background { tabBarAccessor }

            NavigationStack(path: $path) {
                AlbumsGridView(searchText: $searchText, showOnlineSongs: $showOnlineSongs)
                    .navigationTitle("Albums")
                    .safeAreaPadding(.bottom, floatingBarHeight + floatingBarTotalPadding)
            }
            .tabItem { Label("Albums", systemImage: "rectangle.stack") }
            .tag(Panel.albums)
            .background { tabBarAccessor }

            NavigationStack(path: $path) {
                SettingsView()
                    .navigationTitle("Settings")
                    .safeAreaPadding(.bottom, floatingBarHeight + floatingBarTotalPadding)
            }
            .tabItem { Label("Settings", systemImage: "gear") }
            .tag(Panel.settings)
            .background { tabBarAccessor }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                FloatingCurrentSongView()
                    .padding([.leading, .trailing], floatingBarPadding)
                    .background {
                        GeometryReader { proxy in
                            Rectangle()
                                .foregroundStyle(.clear)
                                .onAppear { floatingBarHeight = proxy.size.height }
                                .onChange(of: proxy.size) { floatingBarHeight = proxy.size.height }
                        }
                    }
                    .onTapGesture {
                        // Make sure to hide any keyboard currently on screen
                        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                        scene?.windows.filter {$0.isKeyWindow}.first?.endEditing(true)
                        queueVisible.toggle()
                    }
                Rectangle()
                    .fill(.clear)
                    .frame(height: tabBarHeight + floatingBarPadding)
            }
        }
        .environment(\.floatingBarHeight, floatingBarHeight + floatingBarTotalPadding)
    }

    @ViewBuilder
    private var tabBarAccessor: some View {
        TabBarAccessor { tabBar in
            tabBarHeight = tabBar.bounds.height - tabBar.safeAreaInsets.bottom
        }
    }
}

#endif
