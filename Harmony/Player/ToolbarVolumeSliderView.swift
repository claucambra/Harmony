//
//  ToolbarVolumeSliderView.swift
//  Harmony
//
//  Created by Claudio Cambra on 29/1/24.
//

import SwiftUI

struct ToolbarVolumeSliderView: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        HStack(spacing: 5) {
            Button {
                controller.volume = 0.0
            } label: {
                Label("Mute volume", systemImage: "speaker.slash.fill")
            }
            .labelStyle(.iconOnly)
            .controlSize(.small)

            Slider(value: $controller.volume)
                .controlSize(.small)
                .frame(minWidth: 80)

            Button {
                controller.volume = 1.0
            } label: {
                Label("Maximise volume", systemImage: "speaker.wave.2.fill")
            }
            .labelStyle(.iconOnly)
            .controlSize(.small)
        }
    }
}
