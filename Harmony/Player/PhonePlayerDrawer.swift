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
    private var backgroundColor: Color? {
        guard let currentSong = controller.currentSong,
              let artworkData = currentSong.artwork,
              let inputImage = CIImage(data: artworkData)
        else {
            return nil
        }

        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        guard let filter = CIFilter(
            name: "CIAreaAverage",
            parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]
        ), let outputImage = filter.outputImage else {
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        let opacity = colorScheme == .dark ? 0.4 : 0.2
        return Color(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255
        ).opacity(opacity)
    }

    let cornerRadius = UIMeasurements.cornerRadius
    let borderWidth = UIMeasurements.thinBorderWidth
    let shadowRadius = UIMeasurements.shadowRadius
    let buttonSymbolFontSize = UIMeasurements.largeButtonSymbolFontSize

    var body: some View {
        VStack {
            VStack {
                if queueVisible {
                    PlayerQueueView(rowBackground: Color.clear)
                        .listStyle(.grouped)
                        .scrollContentBackground(.hidden)
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
            backgroundColor
                .animation(Animation.linear(duration: 0.3))
                .ignoresSafeArea()
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

    @ViewBuilder
    func artworkViewWithModifiers(_ view: some View) -> some View {
        view
            .clipShape(.rect(cornerRadius: cornerRadius))
            .shadow(radius: shadowRadius)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.separator, lineWidth: borderWidth)
                    if controller.currentSong?.localUrl == nil,
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
    }
}
#endif
