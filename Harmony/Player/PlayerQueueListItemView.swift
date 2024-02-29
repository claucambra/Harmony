//
//  PlayerQueueListItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 1/2/24.
//

import HarmonyKit
import SwiftUI

struct PlayerQueueListItemView: View {
    @ObservedObject var song: Song
    let isCurrentSong: Bool
    let cornerRadius = UIMeasurements.cornerRadius
    let borderWidth = UIMeasurements.thinBorderWidth
    let shadowRadius = UIMeasurements.shadowRadius

    var body: some View {
        HStack {
            ArtworkView(artwork: song.artwork)
                .frame(height: isCurrentSong ?
                       UIMeasurements.mediumArtworkHeight : UIMeasurements.smallArtworkHeight)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .shadow(radius: isCurrentSong ? shadowRadius : 0)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
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
