//
//  PlayerQueueListItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 1/2/24.
//

import HarmonyKit
import SwiftUI

struct PlayerQueueListItemView: View {
    @State var song: Song
    let isCurrentSong: Bool

    var body: some View {
        HStack {
            BorderedArtworkView(artwork: song.artwork)
                .frame(height: isCurrentSong ?
                       UIMeasurements.mediumArtworkHeight : UIMeasurements.smallArtworkHeight)
            VStack(alignment: .leading) {
                if isCurrentSong {
                    Label("Currently playing", systemImage: "speaker.wave.3.fill")
                        .font(.headline)
                }
                Text(song.title)
                    .lineLimit(1)
                Text(song.artist + " • " + song.album)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
