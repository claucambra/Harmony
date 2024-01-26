//
//  PlayButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct PlayButton: View {
    @ObservedObject var controller = PlayerController.shared
    @State var playButtonImg: String = "play.fill"

    var body: some View {
        Button {
            controller.togglePlayPause()
        } label: {
            Label("Play", systemImage: playButtonImg)
        }
        .labelStyle(.iconOnly)
        .onChange(of: controller.timeControlStatus) {
            switch (controller.timeControlStatus) {
            case .paused:
                playButtonImg = "play.fill"
                break
            case .waitingToPlayAtSpecifiedRate, .playing:
                playButtonImg = "pause.fill"
                break
            default:
                playButtonImg = "play.slash.fill"
                break
            }
        }
    }
}

#Preview {
    PlayButton()
}
