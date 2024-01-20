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

    var body: some View {
        NavigationStack {
            List(availableBackends, id: \.self) { backendDescription in
                Label(backendDescription.name, systemImage: backendDescription.systemImageName)
            }
        }
    }
}
