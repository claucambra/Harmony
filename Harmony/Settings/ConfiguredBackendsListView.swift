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
}
