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

    private let currentSongSectionId = "current-song-section"
    private let futureSongsSectionId = "future-songs-section"
    private let playNextSongsSectionId = "play-next-songs-section"

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
                    .id(currentSongSectionId)
                }
                if !queue.playNextSongs.isEmpty {
                    Section("Playing next") {
                        ForEach(queue.playNextSongs) { song in
                            PlayerQueueListItemView(song: song, isCurrentSong: false)
                        }
                    }
                    .id(playNextSongsSectionId)
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
                    .id(futureSongsSectionId)
                }
            }
            .contextMenu(forSelectionType: Song.ID.self) { ids in
                // TODO
            } primaryAction: { ids in
                for id in ids {
                    PlayerController.shared.playSongFromQueue(instanceId: id)
                }
            }
            .onChange(of: queue.currentSong) {
                #if os(macOS)
                proxy.scrollTo(currentSongSectionId, anchor: .top)
                #else
                if !queue.playNextSongs.isEmpty {
                    proxy.scrollTo(playNextSongsSectionId, anchor: .top)
                } else if !queue.futureSongs.isEmpty {
                    proxy.scrollTo(futureSongsSectionId, anchor: .top)
                }
                #endif
            }
        }
    }
}
