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
            // TODO
        } label: {
            Label("Repeat", systemImage: "repeat")
        }
        .labelStyle(.iconOnly)
    }
}
