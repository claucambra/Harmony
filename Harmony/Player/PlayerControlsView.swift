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
            PlayerScrubberView()
        }
    }
}

#Preview {
    PlayerControlsView()
}
