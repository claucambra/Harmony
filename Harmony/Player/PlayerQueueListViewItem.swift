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
    // TODO: Standardise measurements below
    let borderRadius = 5.0
    let borderWidth = 1.0

    var body: some View {
        HStack {
            SongArtworkView(song: song)
                .frame(height: 40)
                .clipShape(.rect(cornerRadius: borderRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: borderRadius)
                        .stroke(.separator, lineWidth: borderWidth)
                )
            VStack(alignment: .leading) {
                Text(song.title)
                    .lineLimit(1)
                    .bold(playerController.currentSong?.id == song.id)
                Text(song.artist + " • " + song.album)
                    .lineLimit(1)
                    .bold(playerController.currentSong?.id == song.id)
                    .foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
