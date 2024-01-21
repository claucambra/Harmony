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
            ForEach(backendDescription.configDescription) { field in
                if field.valueType == .bool {
                    Toggle(field.title, isOn: binding(for: field.id, fallback: false))
                } else if field.valueType == .float {
                    TextField(field.title, text: binding(for: field.id, fallback: "0.0"))
                } else if field.valueType == .int {
                    TextField(field.title, text: binding(for: field.id, fallback: "0"))
                } else if field.valueType == .string {
                    TextField(field.title, text: binding(for: field.id, fallback: ""))
                } else if field.valueType == .localUrl {
                    HStack {
                        let dirFallback: String = FileManager.default.urls(
                            for: .musicDirectory, in: .userDomainMask
                        ).first?.path ?? ""
                        TextField(field.title, text: binding(for: field.id, fallback: dirFallback))
                        Button(action: {
                            if let localUrl = chooseLocalURL(eligible: .onlyDirectories) {
                                configValues[field.id] = localUrl.path
                            }
                        }) {
                            Label("Add folder…", systemImage: "plus.circle")
                        }
                    }
                }
            }
        }
    }

    func binding<T>(for key: String, fallback: T) -> Binding<T> {
        return Binding(get: {
            return self.configValues[key] as? T ?? fallback
        }, set: {
            self.configValues[key] = $0
        })
    }
}
