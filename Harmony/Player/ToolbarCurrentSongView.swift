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
            VStack {
                HStack {
                    Text(controller.currentSong?.title ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(controller.currentSong?.artist ?? "")
                        .frame(minWidth: 60, alignment: .trailing)
                }
                HStack {
                    Text(controller.displayedCurrentTime)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 8))
                    Text(controller.displayedSongDuration)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.system(size: 8))
                }
                Slider(value: $controller.currentSeconds, in:(0...controller.songDuration)) { editing in
                    controller.scrubState = editing ? .started : .finished
                }
                .frame(maxWidth: .infinity)
                .controlSize(.mini)
            }
        }
        .frame(width: 300)
    }
}

#Preview {
    ToolbarCurrentSongView()
}
