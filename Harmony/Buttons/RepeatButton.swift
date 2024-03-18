//
//  RepeatButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct RepeatButton: View {
    @ObservedObject var queue = PlayerController.shared.queue

    var body: some View {
        Button {
            queue.cycleRepeatState()
        } label: {
            switch queue.repeatState {
            case .disabled:
                Label("Repeat", systemImage: "repeat")
            case .queue:
                Label("Repeat", systemImage: "repeat")
                    .foregroundStyle(.tint)
            case .currentSong:
                Label("Repeat", systemImage: "repeat.1")
                    .foregroundStyle(.tint)
            }
        }
        .labelStyle(.iconOnly)
    }
}
