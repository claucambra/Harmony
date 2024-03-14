//
//  SongContextMenuItems.swift
//  Harmony
//
//  Created by Claudio Cambra on 4/2/24.
//

import HarmonyKit
import SwiftUI

struct SongContextMenuItems: View {
    @ObservedObject var queue = PlayerController.shared.queue
    @State var song: Song

    var body: some View {
        Button {
            queue.insertNextSong(song)
        } label: {
            Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }
        if !song.local, song.downloadState != DownloadState.downloaded.rawValue {
            Button {
                fetchSong(song)
            } label: {
                Label("Keep available offline", systemImage: "square.and.arrow.down")
            }
        } else if !song.local,
                  song.downloadState == DownloadState.downloaded.rawValue ||
                    song.downloadState == DownloadState.downloadedOutdated.rawValue
        {
            Button(role: .destructive) {
                evictSong(song)
            } label: {
                Label("Remove offline copy", systemImage: "trash")
            }
        }
    }
}
