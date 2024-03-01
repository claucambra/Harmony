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
    @State var isCurrentSong = false
    @State var displayArtwork = true
    @State var displayArtist = true

    var body: some View {
        HStack {
            if displayArtwork {
                BorderedArtworkView(artwork: song.artwork)
                    .frame(height: UIMeasurements.smallArtworkHeight)
            }
            VStack(alignment: .leading) {
                Text(song.title)
                    .lineLimit(1)
                if displayArtist {
                    Text(song.artist)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text(Duration.seconds(song.duration).formatted(.time(pattern: .minuteSecond)))
                .foregroundStyle(.secondary)
            Label(
                song.downloaded ? "Available offline" : "Available online only",
                systemImage: song.downloaded ? "arrow.down.circle.fill" : "cloud"
            )
                .foregroundStyle(.tertiary)
                .labelStyle(.iconOnly)
        }
    }
}
