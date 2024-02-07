//
//  PlayerQueueView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import HarmonyKit
import SwiftUI

struct PlayerQueueView: View {
    @ObservedObject var playerController = PlayerController.shared
    @ObservedObject var queue = PlayerController.shared.queue
    @State private var selection: Set<Song.ID> = []

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selection) {
                if !queue.pastSongs.isEmpty {
                    Section("Previously played") {
                        ForEach(queue.pastSongs) { song in
                            PlayerQueueListItemView(song: song, isCurrentSong: false)
                        }
                    }
                }
                if let currentSong = queue.currentSong {
                    Section("Currently playing") {
                        PlayerQueueListItemView(song: currentSong, isCurrentSong: true)
                    }
                }
                if !queue.playNextSongs.isEmpty {
                    Section("Playing next") {
                        ForEach(queue.playNextSongs) { song in
                            PlayerQueueListItemView(song: song, isCurrentSong: false)
                        }
                    }
                }
                if !queue.futureSongs.isEmpty {
                    Section("Upcoming songs") {
                        ForEach(queue.futureSongs) { song in
                            PlayerQueueListItemView(song: song, isCurrentSong: false)
                                .onAppear {
                                    queue.loadNextPageIfNeeded(song: song)
                                }
                        }
                    }
                }
            }
            .contextMenu(forSelectionType: Song.ID.self) { ids in
                // TODO
            } primaryAction: { ids in
                for id in ids {
                    PlayerController.shared.playSongFromQueue(instanceId: id)
                }
            }
        }
    }
}
