//
//  CurrentlyPlayingSongIndicator.swift
//  Harmony
//
//  Created by Claudio Cambra on 27/2/24.
//

import HarmonyKit
import SwiftUI

struct CurrentlyPlayingSongIndicatorView: View {
    let song: Song
    @ObservedObject private var controller = PlayerController.shared
    @State private var currentlyPlaying = false

    var body: some View {
        if controller.currentSong?.identifier == song.identifier {
            Label("Currently playing", systemImage: "speaker.wave.2.circle.fill")
                .labelStyle(.iconOnly)
        } else {
            EmptyView()
        }
    }
}
