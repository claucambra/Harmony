//
//  PlayerButtonStackView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct PlayerButtonStackView: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        HStack {
            Button {
                // TODO
            } label: {
                Label("Shuffle", systemImage: "shuffle")
            }
            .labelStyle(.iconOnly)
            ChangeSongButton(buttonChangeType: .previous)
            PlayButton()
            ChangeSongButton(buttonChangeType: .next)
            Button {
                // TODO
            } label: {
                Label("Repeat", systemImage: "repeat")
            }
            .labelStyle(.iconOnly)
        }
    }
}

#Preview {
    PlayerButtonStackView()
}
