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
            if let currentSong = controller.currentSong {
                SongArtworkView(song: currentSong)
                    .frame(maxHeight: .infinity)
                    .clipShape(.rect(topLeadingRadius: borderRadius, bottomLeadingRadius: borderRadius))
                    .padding([.top, .bottom, .leading], borderWidth)
            } else {
                ZStack(alignment: .center) {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                    Image(systemName: "music.note")
                        .interpolation(.high)
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                        .frame(maxHeight: .infinity)
                        .clipShape(.rect(topLeadingRadius: borderRadius, bottomLeadingRadius: borderRadius))
                        .padding(UIMeasurements.mediumPadding)
                        .padding([.top, .bottom, .leading], borderWidth)
                }
            }
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
}

#Preview {
    ToolbarCurrentSongView()
}
