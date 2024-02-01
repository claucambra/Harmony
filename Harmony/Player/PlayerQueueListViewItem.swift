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
        HStack {
            SongArtworkView(song: song)
                .frame(height: 40)
                .clipShape(.rect(cornerRadius: 5.0))
            VStack(alignment: .leading) {
                Text(song.title)
                    .lineLimit(1)
                    .bold(playerController.currentSong?.instanceId == song.instanceId)
                Text(song.artist + " • " + song.album)
                    .lineLimit(1)
                    .bold(playerController.currentSong?.instanceId == song.instanceId)
                    .foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
