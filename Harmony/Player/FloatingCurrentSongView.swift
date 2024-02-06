//
//  FloatingCurrentSongView.swift
//  Harmony
//
//  Created by Claudio Cambra on 6/2/24.
//

import SwiftUI


struct FloatingCurrentSongView: View {
    @ObservedObject var controller = PlayerController.shared

    // TODO: Standardise measurements below
    let borderRadius = 5.0
    let borderWidth = 1.0
    let shadowRadius = 4.0
    let mainButtonSymbolFontSize = 24.0

    var body: some View {
        HStack {
            SongArtworkView(song: PlayerController.shared.currentSong)
                .clipShape(.rect(cornerRadius: borderRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: borderRadius)
                        .stroke(.separator, lineWidth: borderWidth)
                )
                .frame(height: 48)
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
                .font(.system(size: mainButtonSymbolFontSize))
                .frame(width: 40)
            ChangeSongButton(buttonChangeType: .next)
                .controlSize(.large)
                .font(.system(size: mainButtonSymbolFontSize))
                .frame(width: 40)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 10.0, style: .circular)
                .foregroundStyle(.regularMaterial)
                .shadow(radius: shadowRadius)

        }
    }
}
