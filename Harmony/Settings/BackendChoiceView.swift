//
//  BackendChoiceView.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import HarmonyKit
import SwiftUI

struct BackendChoiceView: View {
    let availableBackends = HarmonyKit.availableBackends
    @State private var selection: BackendDescription? = nil
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(availableBackends, id: \.self, selection: $selection) { backendDescription in
                let disabled = BackendsModel.shared.backends.contains(where: {
                    $0.value.typeDescription.id == backendDescription.id &&
                    $0.value.typeDescription.supportsMultipleInstances == false
                })
                NavigationLink {
                    if disabled {
                        Text("You can only add one \(backendDescription.name) backend.")
                    } else {
                        BackendConfigurationView(
                            backendDescription: backendDescription,
                            configValues: [:],
                            dismiss: dismiss
                        )
                    }
                } label: {
                    BackendChoiceListItemView(
                        backendDescription: backendDescription,
                        selection: $selection
                    )
                }
                .selectionDisabled(disabled)
                .disabled(disabled)
            }
            .navigationTitle("Available backends")
        }
    }
}
