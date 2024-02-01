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
    let horizontalSpacing = 5.0
    let borderRadius = 2.5
    let borderWidth = 1.0

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
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(controller.displayedSongDuration)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Slider(value: $controller.currentSeconds, in:(0...controller.songDuration)) { editing in
                    controller.scrubState = editing ? .started : .finished
                }
                .controlSize(.mini)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 2)
            }
            .padding(.trailing, horizontalSpacing)
        }
        .frame(width: 320)
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
