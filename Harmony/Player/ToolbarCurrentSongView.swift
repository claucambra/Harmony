//
//  PlayerScrubberView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import Foundation

import SwiftUI

struct ToolbarCurrentSongView: View {
    @ObservedObject var controller = PlayerController.shared
    let horizontalSpacing = UIMeasurements.smallPadding
    let borderRadius = UIMeasurements.smallCornerRadius
    let borderWidth = UIMeasurements.thinBorderWidth

    var body: some View {
        HStack(spacing: horizontalSpacing) {
            SongArtworkView(song: controller.currentSong)
                .frame(maxHeight: .infinity)
                .clipShape(.rect(topLeadingRadius: borderRadius, bottomLeadingRadius: borderRadius))
                .padding([.top, .bottom, .leading], borderWidth)
            VStack(spacing: 0) {
                HStack {
                    Text(controller.currentSong?.title ?? "Harmony")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(controller.currentSong?.artist ?? "")
                        .frame(minWidth: 30, alignment: .trailing)
                }
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
                .padding(.bottom, 2)
            }
            .padding(.trailing, horizontalSpacing)
        }
        .frame(width: UIMeasurements.toolbarCurrentSongViewWidth)
        .background(.bar, in: .rect(cornerSize: .init(width: borderRadius, height: borderRadius)))
        .overlay(
            RoundedRectangle(cornerRadius: borderRadius)
                .stroke(.separator, lineWidth: borderWidth)
        )
    }
}

#Preview {
    ToolbarCurrentSongView()
}
