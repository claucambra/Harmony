//
//  ShuffleButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

// TODO
struct ShuffleButton: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        Button {
            // TODO
        } label: {
            Label("Shuffle", systemImage: "shuffle")
        }
        .labelStyle(.iconOnly)
    }
}
