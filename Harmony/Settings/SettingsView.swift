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
                    Label("Backends", systemImage: "arrow.triangle.2.circlepath.circle")
                }
                .tag(Tabs.backends)
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
}
