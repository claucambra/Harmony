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
        Form {
            ForEach(backendDescription.configDescription) { fieldDescription in
                if fieldDescription.valueType == .bool {
                    Toggle(fieldDescription.title, isOn: binding(for: fieldDescription.id, fallbackValue: false))
                } else if fieldDescription.valueType == .float {
                    TextField(fieldDescription.title, text: binding(for: fieldDescription.id, fallbackValue: "0.0"))
                } else if fieldDescription.valueType == .int {
                    TextField(fieldDescription.title, text: binding(for: fieldDescription.id, fallbackValue: "0"))
                } else if fieldDescription.valueType == .string {
                    TextField(fieldDescription.title, text: binding(for: fieldDescription.id, fallbackValue: ""))
                }
            }
        }
    }

    func binding<T>(for key: String, fallbackValue: T) -> Binding<T> {
        return Binding(get: {
            return self.configValues[key] as? T ?? fallbackValue
        }, set: {
            self.configValues[key] = $0
        })
    }
}
