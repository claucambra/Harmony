//
//  FloatingCurrentSongView.swift
//  Harmony
//
//  Created by Claudio Cambra on 6/2/24.
//

import SwiftUI


struct FloatingCurrentSongView: View {
    @ObservedObject var controller = PlayerController.shared

    let cornerRadius = UIMeasurements.cornerRadius
    let borderWidth = UIMeasurements.thinBorderWidth
    let shadowRadius = UIMeasurements.shadowRadius
    let buttonSymbolFontSize = UIMeasurements.mediumButtonSymbolFontSize

    var body: some View {
        HStack {
            if let currentSong = PlayerController.shared.currentSong {
                artworkViewWithModifiers(SongArtworkView(song: currentSong))
            } else {
                artworkViewWithModifiers(PlaceholderArtworkView())
            }
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
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: UIMeasurements.largeCornerRadius, style: .circular)
                .foregroundStyle(.regularMaterial)
                .shadow(radius: shadowRadius)

        }
    }

    @ViewBuilder
    func artworkViewWithModifiers(_ view: some View) -> some View {
        view
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.separator, lineWidth: borderWidth)
                    if controller.currentSong?.localUrl == nil,
                       controller.timeControlStatus == .waitingToPlayAtSpecifiedRate
                    {
                        LoadingIndicatorOverlayView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            )
            .frame(height: UIMeasurements.smallArtworkHeight)
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
