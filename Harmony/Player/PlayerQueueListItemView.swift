//
//  PlayerQueueListItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 1/2/24.
//

import HarmonyKit
import SwiftUI

struct PlayerQueueListItemView: View {
    @ObservedObject var playerController = PlayerController.shared
    let song: Song
    let isCurrentSong: Bool
    // TODO: Standardise measurements below
    let borderRadius = 5.0
    let borderWidth = 1.0
    let shadowRadius = 4.0

    var body: some View {
        HStack {
            SongArtworkView(song: song)
                .frame(height: isCurrentSong ? 60 : 40)
                .clipShape(.rect(cornerRadius: borderRadius))
                .shadow(radius: isCurrentSong ? shadowRadius : 0)
                .overlay(
                    RoundedRectangle(cornerRadius: borderRadius)
                        .stroke(.separator, lineWidth: borderWidth)
                )
                .padding(isCurrentSong ? shadowRadius : 0)
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
