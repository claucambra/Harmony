//
//  FloatingCurrentSongView.swift
//  Harmony
//
//  Created by Claudio Cambra on 6/2/24.
//

import HarmonyKit
import SwiftUI

struct FloatingCurrentSongView: View {
    @ObservedObject var controller = PlayerController.shared

    let shadowRadius = UIMeasurements.shadowRadius
    let buttonSymbolFontSize = UIMeasurements.mediumButtonSymbolFontSize

    var body: some View {
        HStack {
            BorderedArtworkView(artwork: PlayerController.shared.currentSong?.artwork)
                .frame(height: UIMeasurements.smallArtworkHeight)
                .overlay(
                    ZStack {
                        if let currentSong = controller.currentSong,
                           currentSong.downloadState != DownloadState.downloaded.rawValue,
                           controller.timeControlStatus == .waitingToPlayAtSpecifiedRate
                        {
                            LoadingIndicatorOverlayView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                )
            VStack(alignment: .trailing) {
                Text(controller.currentSong?.title ?? "Harmony")
                    .bold()
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if controller.currentSong != nil, controller.currentSong?.artist != "" {
                    Text(controller.currentSong?.artist ?? "")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()
            playbackControlButton(PlayButton())
            playbackControlButton(ChangeSongButton(buttonChangeType: .next))

        }
        .padding(UIMeasurements.smallPadding)
        .background {
            RoundedRectangle(cornerRadius: UIMeasurements.largeCornerRadius, style: .circular)
                .foregroundStyle(.regularMaterial)
                .shadow(radius: shadowRadius)

        }
    }

    @ViewBuilder
    func playbackControlButton(_ button: some View) -> some View {
        button
            .controlSize(.large)
            .foregroundStyle(.foreground)
            .font(.system(size: buttonSymbolFontSize))
            .frame(width: UIMeasurements.mediumButtonSize)
    }
}
