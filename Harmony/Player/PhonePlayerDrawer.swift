//
//  PhonePlayerDrawer.swift
//  Harmony
//
//  Created by Claudio Cambra on 28/1/24.
//

import SwiftUI

#if !os(macOS)
struct PhonePlayerDrawer: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var controller = PlayerController.shared
    @State private var queueVisible = false

    let cornerRadius = UIMeasurements.cornerRadius
    let borderWidth = UIMeasurements.thinBorderWidth
    let shadowRadius = UIMeasurements.shadowRadius
    let buttonSymbolFontSize = UIMeasurements.largeButtonSymbolFontSize

    var body: some View {
        VStack {
            VStack {
                if queueVisible {
                    let maskGradient = LinearGradient(
                        gradient: Gradient(colors: [.black, .black, .black, .clear]),
                        startPoint: .top, endPoint: .bottom
                    )
                    PlayerQueueView(rowBackground: Color.clear)
                        .listStyle(.grouped)
                        .scrollContentBackground(.hidden)
                        .mask(maskGradient)
                } else {
                    VStack {
                        Spacer()
                        BorderedArtworkView(artwork: PlayerController.shared.currentSong?.artwork)
                            .shadow(radius: shadowRadius)
                            .overlay(
                                ZStack {
                                    if let currentSong = controller.currentSong,
                                       !currentSong.downloaded,
                                       controller.timeControlStatus == .waitingToPlayAtSpecifiedRate
                                    {
                                        LoadingIndicatorOverlayView()
                                            .frame(
                                                width: UIMeasurements.smallArtworkHeight,
                                                height: UIMeasurements.smallArtworkHeight
                                            )
                                    }
                                }
                            )
                            .frame(height: UIMeasurements.largeArtworkHeight)
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
                    .padding([.leading, .trailing], UIMeasurements.largePadding)
                }
                VStack(spacing: UIMeasurements.largePadding) {
                    PlayerScrubberView(size: .large)
                        .frame(maxWidth: .infinity)
                    HStack {
                        mainButton(ShuffleButton())
                        Spacer()
                        mainButton(ChangeSongButton(buttonChangeType: .previous))
                        Spacer()
                        mainButton(PlayButton())
                        Spacer()
                        mainButton(ChangeSongButton(buttonChangeType: .next))
                        Spacer()
                        mainButton(RepeatButton())
                    }
                }
                .padding([.bottom], UIMeasurements.veryLargePadding)
                .padding([.leading, .trailing], UIMeasurements.largePadding)
            }
            HStack {
                secondaryButton(AirPlayButton().labelStyle(.iconOnly))
                Spacer()
                secondaryButton(Button {
                    queueVisible.toggle()
                } label: {
                    Label("Toggle queue", systemImage: "list.triangle")
                })
                .labelStyle(.iconOnly)
                .frame(alignment: .trailing)
            }
            .padding([.bottom], UIMeasurements.veryLargePadding)
            .padding([.leading, .trailing], UIMeasurements.largePadding)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .background {
            withAnimation(.linear(duration: 0.3)) {
                ZStack {
                    if let currentSong = controller.currentSong {
                        ArtworkView(artwork: currentSong.artwork, scaleMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Rectangle()
                        .foregroundStyle(.thickMaterial)
                }
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    func mainButton(_ button: some View) -> some View {
        playerButton(button)
            .controlSize(.extraLarge)
            .font(.system(size: buttonSymbolFontSize))
    }

    @ViewBuilder
    func secondaryButton(_ button: some View) -> some View {
        playerButton(button)
            .controlSize(.large)
            .font(.system(size: UIMeasurements.mediumButtonSymbolFontSize))
    }

    @ViewBuilder
    func playerButton(_ button: some View) -> some View {
        button
            .foregroundStyle(.foreground)
    }
}
#endif
