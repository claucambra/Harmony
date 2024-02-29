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
    let horizontalSpacing = UIMeasurements.smallPadding
    let borderRadius = UIMeasurements.smallCornerRadius
    let borderWidth = UIMeasurements.thinBorderWidth

    var body: some View {
        HStack(spacing: horizontalSpacing) {
            artworkWithLoadingOverlay
            VStack(spacing: 0) {
                HStack {
                    Text(controller.currentSong?.title ?? "Harmony")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(controller.currentSong?.artist ?? "")
                        .frame(minWidth: 30, alignment: .trailing)
                }
                PlayerScrubberView(size: .small)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 2)
            }
            .padding(.trailing, horizontalSpacing)
        }
        .frame(width: UIMeasurements.toolbarCurrentSongViewWidth)
        .background(.bar, in: .rect(cornerSize: .init(width: borderRadius, height: borderRadius)))
        .overlay(
            RoundedRectangle(cornerRadius: borderRadius)
                .stroke(.separator, lineWidth: borderWidth)
        )
    }

    @ViewBuilder
    var artworkWithLoadingOverlay: some View {
        ZStack {
            ArtworkView(artwork: controller.currentSong?.artwork)
                .frame(maxHeight: .infinity)
                .clipShape(
                    .rect(topLeadingRadius: borderRadius, bottomLeadingRadius: borderRadius)
                )
            if let currentSong = controller.currentSong,
               !currentSong.downloaded,
               controller.timeControlStatus == .waitingToPlayAtSpecifiedRate
            {
                LoadingIndicatorOverlayView(
                    topLeadingRadius: borderRadius,
                    bottomLeadingRadius: borderRadius,
                    bottomTrailingRadius: 0.0,
                    topTrailingRadius: 0.0
                )
                .frame(maxHeight: .infinity)
                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
            }

        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    ToolbarCurrentSongView()
}
