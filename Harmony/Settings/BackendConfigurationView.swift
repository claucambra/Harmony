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

    var body: some View {
        #if os(macOS)
        HStack {
            Spacer()
            Form {
                ForEach(backendDescription.configDescription) { field in
                    BackendConfigurationFieldView(field: field, configValues: $configValues)
                }
            }
            Spacer()
        }
        #else
        Form {
            Section("Backend configuration") {
                ForEach(backendDescription.configDescription) { field in
                    BackendConfigurationFieldView(field: field, configValues: $configValues)
                }
            }
        }
        #endif
    }
}
