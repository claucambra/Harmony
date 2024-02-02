//
//  RepeatButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

// TODO
struct RepeatButton: View {
    @ObservedObject var queue = PlayerController.shared.queue

    var body: some View {
        Button {
            queue.repeatEnabled.toggle()
        } label: {
            if queue.repeatEnabled {
                Label("Repeat", systemImage: "repeat")
                    .foregroundStyle(.tint)
            } else {
                Label("Repeat", systemImage: "repeat")
            }
        }
        .labelStyle(.iconOnly)
    }
}
