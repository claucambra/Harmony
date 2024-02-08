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
        .onAppear {
            updateButtonSymbol()
        }
        .onChange(of: controller.timeControlStatus) {
            updateButtonSymbol()
        }
    }

    private func updateButtonSymbol() {
        switch controller.timeControlStatus {
        case .paused:
            buttonImage = "play.fill"
        case .waitingToPlayAtSpecifiedRate, .playing:
            buttonImage = "pause.fill"
        default:
            buttonImage = "play.slash.fill"
        }
    }
}

#Preview {
    PlayButton()
}
