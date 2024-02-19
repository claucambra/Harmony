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
    @State var queueVisible = false

    let cornerRadius = UIMeasurements.cornerRadius
    let borderWidth = UIMeasurements.thinBorderWidth
    let shadowRadius = UIMeasurements.shadowRadius
    let buttonSymbolFontSize = UIMeasurements.largeButtonSymbolFontSize

    var body: some View {
        VStack {
            VStack {
                if queueVisible {
                    PlayerQueueView()
                        .listStyle(.plain)
                } else {
                    VStack {
                        Spacer()
                        if let currentSong = PlayerController.shared.currentSong {
                            artworkViewWithModifiers(SongArtworkView(song: currentSong))
                        } else {
                            artworkViewWithModifiers(PlaceholderArtworkView())
                        }
                        Spacer()
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
                        Spacer()
                    }
                }
                VStack(spacing: UIMeasurements.largePadding) {
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
                .padding([.bottom], UIMeasurements.veryLargePadding)
            }
            HStack {
                AirPlayButton()
                    .labelStyle(.iconOnly)
                Spacer()
                Button {
                    queueVisible.toggle()
                } label: {
                    Label("Toggle queue", systemImage: "list.triangle")
                }
                .labelStyle(.iconOnly)
                .frame(alignment: .trailing)
            }
            .padding([.bottom], UIMeasurements.veryLargePadding)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .padding([.leading, .trailing], UIMeasurements.largePadding)
    }

    @ViewBuilder
    func mainButton(_ button: some View) -> some View {
        button
            .controlSize(.large)
            .font(.system(size: buttonSymbolFontSize))
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func artworkViewWithModifiers(_ view: some View) -> some View {
        view
            .clipShape(.rect(cornerRadius: cornerRadius))
            .shadow(radius: shadowRadius)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.separator, lineWidth: borderWidth)
                    if controller.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                        LoadingIndicatorOverlayView()
                            .frame(
                                width: UIMeasurements.smallArtworkHeight,
                                height: UIMeasurements.smallArtworkHeight
                            )
                    }
                }
            )
            .frame(height: UIMeasurements.largeArtworkHeight)
    }
}
#endif
