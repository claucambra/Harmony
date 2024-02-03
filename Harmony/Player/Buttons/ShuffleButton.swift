//
//  ShuffleButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

// TODO
struct ShuffleButton: View {
    @ObservedObject var queue = PlayerController.shared.queue

    var body: some View {
        Button {
            queue.shuffleEnabled.toggle()
        } label: {
            if queue.shuffleEnabled {
                Label("Shuffle", systemImage: "shuffle")
                    .foregroundStyle(.tint)
            } else {
                Label("Shuffle", systemImage: "shuffle")
            }
        }
        .labelStyle(.iconOnly)
    }
}
