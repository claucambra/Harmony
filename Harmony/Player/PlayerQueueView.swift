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
    @State var rowBackground: Color?

    private let currentSongSectionId = "current-song-section"
    private let futureSongsSectionId = "future-songs-section"
    private let playNextSongsSectionId = "play-next-songs-section"

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selection) {
                #if os(macOS) // TODO: iPadOS?
                if !queue.pastSongs.isEmpty {
                    Section("Previously played") {
                        ForEach(queue.pastSongs) { song in
                            PlayerQueueListItemView(song: song, isCurrentSong: false)
                                .listRowBackground(rowBackground)
                        }
                        .onDelete(perform: { indexSet in queue.removePastSongs(indexSet) })
                    }
                }
                #endif
                if let currentSong = queue.currentSong {
                    Section("Currently playing") {
                        PlayerQueueListItemView(song: currentSong, isCurrentSong: true)
                            .listRowBackground(rowBackground)
                    }
                    .id(currentSongSectionId)
                }
                if !queue.playNextSongs.isEmpty {
                    Section("Playing next") {
                        ForEach(queue.playNextSongs) { song in
                            PlayerQueueListItemView(song: song, isCurrentSong: false)
                                .listRowBackground(rowBackground)
                        }
                        .onDelete(perform: { indexSet in queue.removePlayNextSongs(indexSet) })
                    }
                    .id(playNextSongsSectionId)
                }
                if !queue.futureSongs.isEmpty {
                    Section("Upcoming songs") {
                        ForEach(queue.futureSongs) { song in
                            PlayerQueueListItemView(song: song, isCurrentSong: false)
                                .listRowBackground(rowBackground)
                                .onAppear {
                                    queue.loadNextPageIfNeeded(song: song)
                                }
                        }
                        .onDelete(perform: { indexSet in queue.removeFutureSongs(indexSet) })
                    }
                    .id(futureSongsSectionId)
                }
            }
            .contextMenu(forSelectionType: Song.ID.self) { ids in
                // TODO
            } primaryAction: { ids in
                for id in ids {
                    PlayerController.shared.playSongFromQueue(instanceId: id)
                    proxy.scrollTo(currentSongSectionId, anchor: .top)
                }
            }
            .onChange(of: queue.currentSong) {
                #if os(macOS) // TODO: iPadOS?
                proxy.scrollTo(currentSongSectionId, anchor: .top)
                #endif
            }
        }
        .toolbar {
            Button {
                queue.clearPastSongs()
            } label: {
                Label("Clear played songs", systemImage: "text.badge.minus")
            }

            Button {
                queue.clear()
            } label: {
                Label("Clear queue", systemImage: "trash.fill")
            }
        }
    }
}
