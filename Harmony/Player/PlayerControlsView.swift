//
//  PlayerControlsView.swift
//  Harmony
//
//  Created by Claudio Cambra on 25/1/24.
//

import SwiftUI

struct PlayerControlsView: View {
    @ObservedObject var controller = PlayerController.shared
    @State var queueVisible = false

    var body: some View {
        HStack {
            PlayerButtonStackView()
            PlayerScrubberView()
            Button {
                queueVisible = !queueVisible
            } label: {
                Label("Open queue", systemImage: "list.triangle")
            }
            .sheet(isPresented: $queueVisible) {
                PlayerQueueView()
            }
        }
    }
}

#Preview {
    PlayerControlsView()
}
