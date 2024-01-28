//
//  ConfiguredBackendsListView.swift
//  Harmony
//
//  Created by Claudio Cambra on 28/1/24.
//

import SwiftUI
import HarmonyKit

struct ConfiguredBackendsListView: View {
    @ObservedObject var backendsModel = BackendsModel.shared
    @State private var selection = Set<BackendPresentable.ID>()

    #if os(macOS)
    var body: some View {
        List {
            ForEach($backendsModel.backendPresentables) { backendPresentable in
                let presentable = backendPresentable.wrappedValue
                Button {
                    guard let backend = backendsModel.backends[presentable.id] else {
                        return
                    }
                    let window = NSPanel(
                        contentRect: NSRect(x: 0, y: 0, width: 320, height: 240),
                        styleMask: [.fullSizeContentView, .closable, .resizable, .titled],
                        backing: .buffered, defer: false
                    )
                    window.contentView = NSHostingView(rootView: BackendConfigurationView(
                        backendDescription: backend.typeDescription,
                        configValues: backend.configValues
                    ))
                    window.makeKeyAndOrderFront(nil)
                } label: {
                    ConfiguredBackendsListItemView(backendPresentation: presentable)
                        .swipeActions(edge: .leading) {
                            Button {
                                Task {
                                    guard let backend = backendsModel.backends[presentable.id] else {
                                        return
                                    }
                                    await SyncController.shared.syncBackend(backend)
                                }
                            } label: {
                                Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: { indexSet in
                for index in indexSet {
                    let backend = backendsModel.backends.values[index]
                    deleteBackendConfig(
                        id: backend.id, withBackendDescriptionId: backend.typeDescription.id
                    )
                }
            })
        }
    }
    #else
    var body: some View {
        List(selection: $selection) {
            ForEach($backendsModel.backendPresentables) { backendPresentable in
                let presentable = backendPresentable.wrappedValue
                NavigationLink {
                    if let backend = backendsModel.backends[presentable.id] {
                        BackendConfigurationView(
                            backendDescription: backend.typeDescription,
                            configValues: backend.configValues
                        )
                    }
                } label: {
                    ConfiguredBackendsListItemView(backendPresentation: presentable)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        Task {
                            guard let backend = backendsModel.backends[presentable.id] else {
                                return
                            }
                            await SyncController.shared.syncBackend(backend)
                        }
                    } label: {
                        Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .onDelete(perform: { indexSet in
                for index in indexSet {
                    let backend = backendsModel.backends.values[index]
                    deleteBackendConfig(
                        id: backend.id, withBackendDescriptionId: backend.typeDescription.id
                    )
                }
            })
        }
    }
    #endif
}
