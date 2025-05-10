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
    @Environment(\.openWindow) var openWindow
    #endif

    var body: some View {
        List {
            Section("Configured backends") {
                ForEach($backendsModel.backendPresentables) { backendPresentable in
                    let presentable = backendPresentable.wrappedValue
                    listItemView(presentable: presentable)
                        .swipeActions(edge: .leading) {
                            SyncBackendButton(backendPresentable: presentable)
                        }
                        .contextMenu {
                            SyncBackendButton(backendPresentable: presentable)
                            Button("Delete") {
                                let identifier = presentable.backendId
                                guard let backend = backendsModel.backends[identifier] else {
                                    print("Could not delete unknown container")
                                    return
                                }
                                deleteBackendConfig(
                                    id: backend.backendId,
                                    withBackendDescriptionId: backend.typeDescription.id
                                )
                            }
                        }
                }
                .onDelete(perform: { indexSet in
                    for index in indexSet {
                        let backend = backendsModel.backends.values[index]
                        deleteBackendConfig(
                            id: backend.backendId, withBackendDescriptionId: backend.typeDescription.id
                        )
                    }
                })
                #if os(macOS)
                Button(action: {
                    openWindow(id: "backend-creator")
                }) {
                    Label("Configure new backend...", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                #else
                NavigationLink {
                    BackendChoiceView()
                } label: {
                    Label("Configure new backend...", systemImage: "plus.circle")
                }
                #endif
            }
        }
    }

    #if os(macOS)
    func openConfigWindowForBackend(_ backend: any Backend) {
        let window = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: UIMeasurements.smallWindowWidth,
                height: UIMeasurements.smallWindowHeight
            ),
            styleMask: [.fullSizeContentView, .closable, .resizable, .titled],
            backing: .buffered, defer: false
        )
        window.contentView = NSHostingView(rootView: BackendConfigurationView(
            backendDescription: backend.typeDescription,
            configValues: backend.configValues
        ).padding(UIMeasurements.largePadding))
        window.makeKeyAndOrderFront(nil)
    }
    #endif

    @ViewBuilder
    private func listItemView(presentable: BackendPresentable) -> some View {
        #if os(macOS)
        Button {
            guard let backend = backendsModel.backends[presentable.backendId] else { return }
            openConfigWindowForBackend(backend)
        } label: {
            ConfiguredBackendsListItemView(backendPresentation: presentable)
        }
        .buttonStyle(.plain)
        #else
        NavigationLink {
            if let backend = backendsModel.backends[presentable.backendId] {
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
