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
            Button {
                controller.playPreviousSong()
            } label: {
                Label("Previous", systemImage: "backward.fill")
            }
            Button {
                controller.togglePlayPause()
            } label: {
                Label("Play", systemImage: playButtonImg)
            }
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
            Button {
                controller.playNextSong()
            } label: {
                Label("Next", systemImage: "forward.fill")
            }
            Button {
                // TODO
            } label: {
                Label("Repeat", systemImage: "repeat")
            }
        }
    }
}
