//
//  PhonePlayerDrawer.swift
//  Harmony
//
//  Created by Claudio Cambra on 28/1/24.
//

import SwiftUI

#if !os(macOS)
struct PhonePlayerDrawer: View {
    @ObservedObject var controller = PlayerController.shared

    let cornerRadius = UIMeasurements.cornerRadius
    let borderWidth = UIMeasurements.thinBorderWidth
    let shadowRadius = UIMeasurements.shadowRadius
    let buttonSymbolFontSize = UIMeasurements.largeButtonSymbolFontSize

    var body: some View {
        VStack {
            VStack {
                SongArtworkView(song: PlayerController.shared.currentSong)
                    .clipShape(.rect(cornerRadius: cornerRadius))
                    .shadow(radius: shadowRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.separator, lineWidth: borderWidth)
                    )
                    .frame(height: UIMeasurements.largeArtworkHeight)
                Text(controller.currentSong?.title ?? "Harmony")
                    .bold()
                    .font(.title)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                if controller.currentSong != nil, controller.currentSong?.artist != "" {
                    Text(controller.currentSong?.artist ?? "")
                        .font(.title2)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                VStack(spacing: UIMeasurements.mediumPadding) {
                    PlayerScrubberView(size: .large)
                        .frame(maxWidth: .infinity)
                    HStack {
                        mainButton(ShuffleButton())
                        mainButton(ChangeSongButton(buttonChangeType: .previous))
                        mainButton(PlayButton())
                        mainButton(ChangeSongButton(buttonChangeType: .next))
                        mainButton(RepeatButton())
                    }
                }
            }
            .padding([.top], UIMeasurements.veryLargePadding)
            .padding([.leading, .trailing, .bottom], UIMeasurements.largePadding)
            PlayerQueueView()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    func mainButton(_ button: some View) -> some View {
        button
            .controlSize(.large)
            .font(.system(size: buttonSymbolFontSize))
            .frame(maxWidth: .infinity)
    }
}
#endif
