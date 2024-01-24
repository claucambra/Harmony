//
//  BackendsSettingsView.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import SwiftUI
import HarmonyKit

struct BackendsSettingsView: View {
    let backendsModel = BackendsModel.shared

    #if os(macOS)
    @Environment(\.openWindow) var openWindow
    #endif

    var body: some View {
        VStack {
            listView.padding(10)
            Button(action: {
                #if os(macOS)
                openWindow(id: "backend-creator")
                #endif
            }) {
                Label("Configure new backend...", systemImage: "plus.circle")
            }
        }
    }

    @ViewBuilder
    var listView: some View {
        if backendsModel.configurations.isEmpty {
            emptyListView
        } else {
            objectsListView
        }
    }

    var emptyListView: some View {
        Text("No configured backends.")
            .font(.largeTitle)
    }

    var objectsListView: some View {
        List(backendsModel.backends, id: \.id) { backend in
            Text(backend.primaryDisplayString)
        }
    }
}
