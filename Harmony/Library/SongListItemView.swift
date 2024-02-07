//
//  SongListItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 8/2/24.
//

import HarmonyKit
import SwiftUI

struct SongListItemView: View {
    let song: DatabaseSong
    let isCurrentSong: Bool
    // TODO: Standardise measurements below
    let borderRadius = 5.0
    let borderWidth = 1.0

    var body: some View {
        let actualSong = song.toSong() // TODO: Find a better way to get the artwork
        HStack {
            SongArtworkView(song: actualSong)
                .frame(height: 40)
                .clipShape(.rect(cornerRadius: borderRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: borderRadius)
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
        }
    }
}
