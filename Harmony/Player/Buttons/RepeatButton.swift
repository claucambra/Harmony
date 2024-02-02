//
//  RepeatButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

// TODO
struct RepeatButton: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        Button {
            controller.repeatEnabled.toggle()
        } label: {
            if controller.repeatEnabled {
                Label("Repeat", systemImage: "repeat")
                    .foregroundStyle(.tint)
            } else {
                Label("Repeat", systemImage: "repeat")
            }
        }
        .labelStyle(.iconOnly)
    }
}
