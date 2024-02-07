//
//  BackendConfigurationFieldView.swift
//  Harmony
//
//  Created by Claudio Cambra on 21/1/24.
//

import HarmonyKit
import SwiftUI

struct BackendConfigurationFieldView: View {
    let field: BackendConfigurationField
    @Binding var configValues: BackendConfiguration
    #if !os(macOS)
    @State private var filePickerVisible = false
    #endif

    var body: some View {
        if field.valueType == .bool {
            Toggle(field.title,
                   isOn: binding(for: field.id, fallback: field.defaultValue as? Bool ?? false))
        } else if field.valueType == .float {
            TextField(field.title, 
                      text: binding(for: field.id, fallback: field.defaultValue as? String ?? "0"))
        } else if field.valueType == .int {
            TextField(field.title, 
                      text: binding(for: field.id, fallback: field.defaultValue as? String ?? "0"))
        } else if field.valueType == .string {
            TextField(field.title, 
                      text: binding(for: field.id, fallback: field.defaultValue as? String ?? ""))
        } else if field.valueType == .localUrl {
            TextField(field.title, 
                      text: binding(for: field.id, fallback: field.defaultValue as? String ?? ""))
            Button(action: {
                #if os(macOS)
                if let localUrl = chooseLocalURL(eligible: .onlyDirectories) {
                    configValues[field.id] = localUrl
                }
                #else
                filePickerVisible = true
                #endif
            }) {
                Label("Choose folder…", systemImage: "folder.fill")
            }
            #if os(iOS)
            .sheet(isPresented: $filePickerVisible) {
                FilePickerRepresentable(
                    types: [.directory, .folder], allowMultiple: true, onPicked: { urls in
                        if let localUrl = urls.first {
                            configValues[field.id] = localUrl
                        }
                })
            }
            #endif
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
