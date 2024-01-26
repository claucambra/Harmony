//
//  PlayerControlsView.swift
//  Harmony
//
//  Created by Claudio Cambra on 25/1/24.
//

import SwiftUI

struct PlayerControlsView: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        HStack {
            PlayerButtonStackView()
            Slider(value: $controller.currentSeconds, in:(0...controller.songDuration)) { editing in
                controller.scrubState = editing ? .started : .finished
            }
            .frame(minWidth: 300, maxWidth: .infinity)
        }
    }
}
