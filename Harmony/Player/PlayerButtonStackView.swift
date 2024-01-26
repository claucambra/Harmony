//
//  PlayerButtonStackView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct PlayerButtonStackView: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        HStack {
            ShuffleButton()
            ChangeSongButton(buttonChangeType: .previous)
            PlayButton()
            ChangeSongButton(buttonChangeType: .next)
            RepeatButton()
        }
    }
}

#Preview {
    PlayerButtonStackView()
}
