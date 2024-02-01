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
        List(selection: $selection) {
            ForEach(queue.songs) { song in
                PlayerQueueListViewItem(song: song)
                    .onAppear {
                        queue.loadNextPageIfNeeded(song: song)
                    }
            }
        }
        .contextMenu(forSelectionType: Song.ID.self) { ids in
        } primaryAction: { ids in
            for id in ids {
                PlayerController.shared.playSongFromQueue(instanceId: id)
            }
        }
    }
}
