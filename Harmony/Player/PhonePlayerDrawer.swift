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
    // TODO: Standardise measurements below
    let borderRadius = 5.0
    let borderWidth = 1.0
    let shadowRadius = 4.0
    let mainButtonSymbolFontSize = 32

    var body: some View {
        VStack {
            VStack {
                SongArtworkView(song: PlayerController.shared.currentSong)
                    .clipShape(.rect(cornerRadius: borderRadius))
                    .shadow(radius: shadowRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: borderRadius)
                            .stroke(.separator, lineWidth: borderWidth)
                    )
                    .frame(height: 200)
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
                VStack(spacing: 10) {
                    Slider(value: $controller.currentSeconds, in:(0...controller.songDuration)) { editing in
                        controller.scrubState = editing ? .started : .finished
                    }
                    .frame(maxWidth: .infinity)
                    HStack {
                        ShuffleButton()
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 32))
                        ChangeSongButton(buttonChangeType: .previous)
                            .controlSize(.large)
                            .font(.system(size: 32))
                            .frame(maxWidth: .infinity)
                        PlayButton()
                            .controlSize(.large)
                            .font(.system(size: 32))
                            .frame(maxWidth: .infinity)
                        ChangeSongButton(buttonChangeType: .next)
                            .controlSize(.large)
                            .font(.system(size: 32))
                            .frame(maxWidth: .infinity)
                        RepeatButton()
                            .controlSize(.large)
                            .font(.system(size: 32))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding([.top], 40)
            .padding([.leading, .trailing, .bottom], 20)
            PlayerQueueView()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
#endif
