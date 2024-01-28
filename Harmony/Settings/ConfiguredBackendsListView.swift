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

    var body: some View {
        List {
            ForEach($backendsModel.backendPresentables) { backendPresentable in
                let presentable = backendPresentable.wrappedValue
                listItemView(presentable: presentable)
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

    func openConfigWindowForBackend(_ backend: any Backend) {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 240),
            styleMask: [.fullSizeContentView, .closable, .resizable, .titled],
            backing: .buffered, defer: false
        )
        window.contentView = NSHostingView(rootView: BackendConfigurationView(
            backendDescription: backend.typeDescription,
            configValues: backend.configValues
        ).padding(20))
        window.makeKeyAndOrderFront(nil)
    }

    @ViewBuilder
    private func listItemView(presentable: BackendPresentable) -> some View {
        #if os(macOS)
        Button {
            guard let backend = backendsModel.backends[presentable.id] else { return }
            openConfigWindowForBackend(backend)
        } label: {
            ConfiguredBackendsListItemView(backendPresentation: presentable)
        }
        .buttonStyle(.plain)
        #else
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
        #endif
    }
}
