//
//  PlayerScrubberView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import Foundation

import SwiftUI

struct PlayerScrubberView: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        HStack {
            Text(controller.displayedCurrentTime)
                .frame(width: 50)
            Slider(value: $controller.currentSeconds, in:(0...controller.songDuration)) { editing in
                controller.scrubState = editing ? .started : .finished
            }
            .frame(minWidth: 300, maxWidth: .infinity)
            Text(controller.displayedSongDuration)
                .frame(width: 50)
        }
    }
}

#Preview {
    PlayerScrubberView()
}
