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
                NavigationLink {
                    BackendConfigurationView(
                        backendDescription: backendDescription,
                        configValues: [:],
                        dismiss: dismiss
                    )
                } label: {
                    BackendChoiceListItemView(
                        backendDescription: backendDescription,
                        selection: $selection
                    )
                }
            }
            .navigationTitle("Available backends")
        }
    }
}
