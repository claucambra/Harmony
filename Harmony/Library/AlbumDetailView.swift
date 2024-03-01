//
//  AlbumDetailView.swift
//  Harmony
//
//  Created by Claudio Cambra on 1/3/24.
//

import HarmonyKit
import SwiftUI

struct AlbumDetailView: View {
    let album: Album

    var body: some View {
        List {
            HStack {
                BorderedArtworkView(artwork: album.artwork)
                    .frame(height: UIMeasurements.largeArtworkHeight)

                VStack(alignment: .leading) {
                    Text(album.title.isEmpty ? "Unknown album" : album.title)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.leading)
                    Text(album.artist ?? "Unknown artist")
                        .font(.title)
                        .multilineTextAlignment(.leading)
                    Text(album.genre == nil || album.genre!.isEmpty
                            ? "Unknown genre"
                            : album.genre ?? "Unknown genre")
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
            }
            ForEach(album.songs) { song in
                Text(song.title)
            }
        }
    }
}
