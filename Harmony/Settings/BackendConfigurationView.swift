//
//  BackendConfigurationView.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import HarmonyKit
import SwiftUI

struct BackendConfigurationView: View {
    let backendDescription: BackendDescription
    @State var configValues: [String: Any] = [:]
    var dismiss: DismissAction

    var body: some View {
        platformSpecificView
        .navigationTitle("New " + backendDescription.name)
        .toolbar {
            Button("Save") {
                saveConfig(configValues, forBackend: backendDescription)
                dismiss()
            }
        }
    }

    @ViewBuilder var platformSpecificView: some View {
        #if os(macOS)
        macOSView
        #else
        defaultView
        #endif
    }

    var macOSView: some View {
        HStack {
            Spacer()
            Form {
                ForEach(backendDescription.configDescription) { field in
                    BackendConfigurationFieldView(field: field, configValues: $configValues)
                }
            }
            Spacer()
        }
    }

    var defaultView: some View {
        Form {
            Section("Backend configuration") {
                ForEach(backendDescription.configDescription) { field in
                    BackendConfigurationFieldView(field: field, configValues: $configValues)
                }
            }
        }
    }
}
