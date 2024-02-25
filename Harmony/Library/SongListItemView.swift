//
//  SongListItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 8/2/24.
//

import HarmonyKit
import SwiftUI

struct SongListItemView: View {
    @ObservedObject var song: Song
    let isCurrentSong: Bool
    let cornerRadius = UIMeasurements.cornerRadius
    let borderWidth = UIMeasurements.thinBorderWidth

    var body: some View {
        HStack {
            SongArtworkView(song: song)
                .frame(height: UIMeasurements.smallArtworkHeight)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.separator, lineWidth: borderWidth)
                )
            VStack(alignment: .leading) {
                if isCurrentSong {
                    Label("Currently playing", systemImage: "speaker.wave.3.fill")
                        .font(.headline)
                }
                Text(song.title)
                    .lineLimit(1)
                Text(song.artist)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Label(
                song.downloaded ? "Available offline" : "Available online only",
                systemImage: song.downloaded ? "arrow.down.circle.fill" : "cloud"
            )
                .foregroundStyle(.tertiary)
                .labelStyle(.iconOnly)
        }
    }
}
