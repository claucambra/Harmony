//
//  HarmonyApp.swift
//  Harmony
//
//  Created by Claudio Cambra on 7/1/24.
//

import SwiftData
import SwiftUI

@main
struct HarmonyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DatabaseSong.self)
        #if os(macOS)
        .windowToolbarStyle(.unified(showsTitle: false))
        #endif
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
