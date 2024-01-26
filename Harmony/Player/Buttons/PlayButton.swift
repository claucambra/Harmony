//
//  PlayButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct PlayButton: View {
    @ObservedObject var controller = PlayerController.shared
    @State var buttonImage: String = "play.fill"
    @State var buttonText: String = "Play"

    var body: some View {
        Button {
            controller.togglePlayPause()
        } label: {
            Label(buttonText, systemImage: buttonImage)
        }
        .labelStyle(.iconOnly)
        .onChange(of: controller.timeControlStatus) {
            switch (controller.timeControlStatus) {
            case .paused:
                buttonImage = "play.fill"
                break
            case .waitingToPlayAtSpecifiedRate, .playing:
                buttonImage = "pause.fill"
                break
            default:
                buttonImage = "play.slash.fill"
                break
            }
        }
    }
}

#Preview {
    PlayButton()
}
