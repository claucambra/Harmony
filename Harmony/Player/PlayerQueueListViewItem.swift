//
//  PlayerQueueListViewItem.swift
//  Harmony
//
//  Created by Claudio Cambra on 1/2/24.
//

import HarmonyKit
import SwiftUI

struct PlayerQueueListViewItem: View {
    @ObservedObject var playerController = PlayerController.shared
    let song: Song

    var body: some View {
        Text(song.title)
            .bold(playerController.currentSong?.instanceId == song.instanceId)
    }
}
