//
//  KeepOfflineButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 18/3/24.
//

import HarmonyKit
import SwiftUI

struct KeepOfflineButton: View {
    let song: Song
    var body: some View {
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
