//
//  SongDownloadStateView.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/3/24.
//

import HarmonyKit
import SwiftUI

struct SongDownloadStateView: View {
    @State var song: Song
    @State private var progress = 0.0

    var body: some View {
        if song.downloadState == DownloadState.downloading.rawValue {
            ProgressView(value: song.downloadProgress)
                .padding(UIMeasurements.smallPadding)
                .frame(width: UIMeasurements.largePadding * 3)
        } else {
            DownloadStateLabelView(state: song.downloadState)
        }
    }
}
