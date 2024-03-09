//
//  DownloadStateLabelView.swift
//  Harmony
//
//  Created by Claudio Cambra on 7/3/24.
//

import HarmonyKit
import SwiftUI

struct DownloadStateLabelView: View {
    let state: Int

    var body: some View {
        switch state {
        case DownloadState.downloaded.rawValue:
            Label("Available offline", systemImage: "arrow.down.circle.fill")
                .labelStyle(.iconOnly)
        case DownloadState.downloadedOutdated.rawValue:
            Label("Available offline (outdated)", systemImage: "arrow.down.circle.dotted")
                .labelStyle(.iconOnly)
        case DownloadState.downloading.rawValue:
            Label("Downloading", systemImage: "icloud.and.arrow.down.fill")
                .labelStyle(.iconOnly)
        case DownloadState.notDownloaded.rawValue:
            Label("Available online only", systemImage: "cloud")
                .labelStyle(.iconOnly)
        default:
            Label("Unknown", systemImage: "exclamationmark.icloud")
                .labelStyle(.iconOnly)
        }
    }
}
