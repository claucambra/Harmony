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
            VStack {
                Text(controller.currentSong?.title ?? "")
                Text(controller.currentSong?.artist ?? "")
            }
        }
        .frame(width: 150)
    }
}

#Preview {
    PlayerCurrentSongView()
}
