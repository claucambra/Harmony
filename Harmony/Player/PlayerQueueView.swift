//
//  PlayerQueueView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct PlayerQueueView: View {
    @ObservedObject var playerController = PlayerController.shared
    @ObservedObject var queue = PlayerController.shared.queue

    var body: some View {
        List {
            ForEach(queue.songs) { song in
                Text(song.title)
                    .bold(playerController.currentSong?.identifier == song.identifier)
                    .onAppear {
                        queue.loadNextPageIfNeeded(song: song)
                    }
            }
        }
    }
}
