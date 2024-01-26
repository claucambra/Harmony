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
            Slider(value: $controller.currentSeconds, in:(0...controller.songDuration)) { editing in
                controller.scrubState = editing ? .started : .finished
            }
        }
    }
}

#Preview {
    PlayerScrubberView()
}
