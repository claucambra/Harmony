//
//  ConfiguredBackendsListView.swift
//  Harmony
//
//  Created by Claudio Cambra on 28/1/24.
//

import SwiftUI

struct ConfiguredBackendsListView: View {
    @ObservedObject var backendsModel = BackendsModel.shared

    var body: some View {
        List {
            ForEach(backendsModel.backends.values, id: \.id) { backend in
                ConfiguredBackendsListItemView(backendPresentation: backend.presentation)
                    .swipeActions(edge: .leading) {
                        Button {
                            Task {
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
