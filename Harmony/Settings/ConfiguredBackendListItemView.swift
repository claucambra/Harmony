//
//  ConfiguredBackendListItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import HarmonyKit
import SwiftUI

struct ConfiguredBackendListItemView: View {
    @ObservedObject var backendPresentation: BackendPresentable

    var body: some View {
        HStack {
            Image(systemName: backendPresentation.systemImage)
            VStack(alignment: .leading) {
                Text(backendPresentation.primary).fontWeight(.bold)
                Text(backendPresentation.config)
                Text(backendPresentation.state)
            }
        }
    }
}
