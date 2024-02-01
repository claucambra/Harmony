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
                ForEach(queue.songs) { song in
                    PlayerQueueListViewItem(song: song)
                        .onAppear {
                            queue.loadNextPageIfNeeded(song: song)
                        }
                        .onChange(of: playerController.currentSong) {
                            guard playerController.currentSong?.id == song.id else { return }
                            withAnimation {
                                proxy.scrollTo(song.id, anchor: .top)
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
