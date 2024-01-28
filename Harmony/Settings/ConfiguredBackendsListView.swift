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

    var body: some View {
        List {
            ForEach($backendsModel.backendPresentables, id: \.id) { backendPresentation in
                let presentation = backendPresentation.wrappedValue
                ConfiguredBackendsListItemView(backendPresentation: presentation)
                    .swipeActions(edge: .leading) {
                        Button {
                            Task {
                                guard let backend = 
                                        backendsModel.backends[presentation.backendId] else {
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
