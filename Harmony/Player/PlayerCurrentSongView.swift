//
//  PlayerCurrentSongView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct PlayerCurrentSongView: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        HStack {
            HStack {
                CurrentSongArtworkView()
                    .frame(maxHeight: .infinity)
                VStack {
                    Text(controller.currentSong?.title ?? "")
                        .frame(maxWidth: .infinity)
                    Text(controller.currentSong?.artist ?? "")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(width: 150)
    }
}

#Preview {
    PlayerCurrentSongView()
}
