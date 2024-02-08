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
            SongArtworkView(song: PlayerController.shared.currentSong)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.separator, lineWidth: borderWidth)
                )
                .frame(height: UIMeasurements.smallArtworkHeight)
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
            PlayButton()
                .controlSize(.large)
                .font(.system(size: buttonSymbolFontSize))
                .frame(width: UIMeasurements.mediumButtonSize)
            ChangeSongButton(buttonChangeType: .next)
                .controlSize(.large)
                .font(.system(size: buttonSymbolFontSize))
                .frame(width: UIMeasurements.mediumButtonSize)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: UIMeasurements.largeCornerRadius, style: .circular)
                .foregroundStyle(.regularMaterial)
                .shadow(radius: shadowRadius)

        }
    }
}
