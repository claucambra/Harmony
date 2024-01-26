//
//  HarmonyApp.swift
//  Harmony
//
//  Created by Claudio Cambra on 7/1/24.
//

import SwiftUI

@main
struct HarmonyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        #if os(macOS)
        Settings {
            SettingsView()
        }
        Window("Add a new backend", id: "backend-creator") {
            BackendChoiceView()
        }
        #endif
    }
}
