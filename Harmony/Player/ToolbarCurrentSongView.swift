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

    var body: some View {
        HStack {
            CurrentSongArtworkView()
                .frame(maxHeight: .infinity)
                .clipShape(.rect(topLeadingRadius: 5, bottomLeadingRadius: 5))
            VStack {
                HStack {
                    Text(controller.currentSong?.title ?? "")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(controller.currentSong?.artist ?? "")
                        .frame(minWidth: 30, alignment: .trailing)
                }
                HStack {
                    Text(controller.displayedCurrentTime)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(controller.displayedSongDuration)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Slider(value: $controller.currentSeconds, in:(0...controller.songDuration)) { editing in
                    controller.scrubState = editing ? .started : .finished
                }
                .frame(maxWidth: .infinity)
                .controlSize(.mini)
            }
            .padding(.trailing, 5)
        }
        .frame(width: 320)
        .background(.bar, in: .rect(cornerSize: .init(width: 5, height: 5)))
    }
}

#Preview {
    ToolbarCurrentSongView()
}
