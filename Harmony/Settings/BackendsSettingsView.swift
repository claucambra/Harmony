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
            listView.frame(maxWidth: .infinity, maxHeight: .infinity)
            #if os(macOS)
            Button(action: {
                openWindow(id: "backend-creator")
            }) {
                Label("Configure new backend...", systemImage: "plus.circle")
            }
            #else
            NavigationLink {
                BackendChoiceView()
            } label: {
                Label("Configure new backend...", systemImage: "plus.circle")
            }
            #endif
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
        List {
            ForEach(backendsModel.backends.values, id: \.id) { backend in
                ConfiguredBackendListItemView(backendPresentation: backend.presentation)
            }.onDelete(perform: { indexSet in
                // meep
            })
        }
    }
}
