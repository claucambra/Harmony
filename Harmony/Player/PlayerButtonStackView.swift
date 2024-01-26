//
//  PlayerButtonStackView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct PlayerButtonStackView: View {
    @ObservedObject var controller = PlayerController.shared
    @State var playButtonImg: String = "play.fill"

    var body: some View {
        HStack {
            Button {
                // TODO
            } label: {
                Label("Shuffle", systemImage: "shuffle")
            }
            .labelStyle(.iconOnly)
            Button {
                controller.playPreviousSong()
            } label: {
                Label("Previous", systemImage: "backward.fill")
            }
            .labelStyle(.iconOnly)
            PlayButton()
            Button {
                controller.playNextSong()
            } label: {
                Label("Next", systemImage: "forward.fill")
            }
            .labelStyle(.iconOnly)
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
