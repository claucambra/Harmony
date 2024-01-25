//
//  SettingsView.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, appearance, backends
    }

    var body: some View {
        TabView {
            BackendsSettingsView()
                .tabItem {
                    labelForTab(.backends)
                }
                .tag(Tabs.backends)
        }
        .padding(20)
        .frame(width: 375, height: 150)

    private func labelForTab(_ tab: Tabs) -> some View {
        switch (tab) {
        case .general:
            Label("General", systemImage: "gear")
        case .appearance:
            Label("Appearance", systemImage: "paintbrush.pointed.fill")
        case .backends:
            Label("Backends", systemImage: "arrow.triangle.2.circlepath.circle")
        }
    }
}
