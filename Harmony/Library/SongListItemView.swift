//
//  SongListItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 8/2/24.
//

import HarmonyKit
import SwiftUI

struct SongListItemView: View {
    @State var song: Song
    @State var isCurrentSong = false
    @State var displayArtwork = true
    @State var displayArtist = true
    @State var displayTrackNumber = false

    var body: some View {
        HStack {
            if displayTrackNumber {
                Text("\(song.trackNumber)")
                    .foregroundStyle(.secondary)
            }
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
            SongDownloadStateView(song: song)
                .foregroundStyle(.tertiary)
        }
        .swipeActions(edge: .trailing) {  // TODO: Deduplicate this and context menu
            Button {
                if !song.local,
                   song.downloadState == DownloadState.downloaded.rawValue ||
                   song.downloadState == DownloadState.downloadedOutdated.rawValue
                {
                    evictSong(song)
                } else if !song.local {
                    fetchSong(song)
                }
            } label: {
                if song.downloadState == DownloadState.downloaded.rawValue ||
                   song.downloadState == DownloadState.downloadedOutdated.rawValue
                {
                    Label("Remove offline copy", systemImage: "trash")
                } else {
                    Label("Keep available offline", systemImage: "square.and.arrow.down")
                }
            }
        }
    }
}
