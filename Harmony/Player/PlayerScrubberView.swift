//
//  PlayerScrubberView.swift
//  Harmony
//
//  Created by Claudio Cambra on 8/2/24.
//

import SwiftUI

struct PlayerScrubberView: View {
    enum ScrubberSize { case small, large }

    @ObservedObject var controller = PlayerController.shared
    let size: ScrubberSize
    let timeLabelFontSize = UIMeasurements.smallFontSize
    var sliderControlSize: ControlSize {
        switch size {
        case .small:
            return .mini
        case .large:
            return .large
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(controller.displayedCurrentTime)
                    .font(.system(size: timeLabelFontSize))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(controller.displayedSongDuration)
                    .font(.system(size: timeLabelFontSize))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Slider(
                value: $controller.currentSeconds,
                in:(0...controller.songDuration)
            ) { editing in
                controller.scrubState = editing ? .started : .finished
            }
            .controlSize(sliderControlSize)
            .frame(maxWidth: .infinity)
        }
    }
}
