//
//  PlayerScrubberView.swift
//  Harmony
//
//  Created by Claudio Cambra on 8/2/24.
//

import SwiftUI

struct PlayerScrubberView: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(controller.displayedCurrentTime)
                    .font(.system(size: UIMeasurements.smallFontSize))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(controller.displayedSongDuration)
                    .font(.system(size: UIMeasurements.smallFontSize))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Slider(
                value: $controller.currentSeconds,
                in:(0...controller.songDuration)
            ) { editing in
                controller.scrubState = editing ? .started : .finished
            }
            .controlSize(.mini)
            .frame(maxWidth: .infinity)
        }
    }
}
