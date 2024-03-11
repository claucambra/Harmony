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

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selection) {
                #if os(macOS) // TODO: iPadOS?
                if !queue.pastSongs.isEmpty {
                    Section {
                        ForEach(queue.pastSongs) { song in
                            PlayerQueueListItemView(song: song, isCurrentSong: false)
                                .listRowBackground(rowBackground)
                        }
                        .onDelete(perform: { indexSet in queue.removePastSongs(indexSet) })
                    } header: {
                        HStack {
                            Text("Previously played")
                            Spacer()
                            Button {
                                queue.clearPastSongs()
                            } label: {
                                Label("Clear played songs", systemImage: "trash.fill")
                            }
                            .buttonStyle(.borderless)
                            .labelStyle(.iconOnly)
                        }
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
                }
                if !queue.futureSongs.isEmpty {
                    Section {
                        ForEach(queue.futureSongs) { song in
                            PlayerQueueListItemView(song: song, isCurrentSong: false)
                                .listRowBackground(rowBackground)
                                .onAppear {
                                    queue.loadNextPageIfNeeded(song: song)
                                }
                        }
                        .onDelete(perform: { indexSet in queue.removeFutureSongs(indexSet) })
                    } header: {
                        HStack {
                            Text("Upcoming songs")
                            Spacer()
                            Button {
                                queue.clearSongsAfterCurrent()
                            } label: {
                                Label("Clear upcoming songs", systemImage: "trash.fill")
                            }
                            .buttonStyle(.borderless)
                            .labelStyle(.iconOnly)
                        }
                    }
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
    }
}
