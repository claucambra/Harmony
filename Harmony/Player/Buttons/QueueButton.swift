//
//  QueueButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

// TODO
struct QueueButton: View {
    @ObservedObject var controller = PlayerController.shared
    @State var queueVisible = false

    var body: some View {
        Button {
            queueVisible = !queueVisible
        } label: {
            Label("Open queue", systemImage: "list.triangle")
        }
        .sheet(isPresented: $queueVisible) {
            PlayerQueueView()
        }
        .labelStyle(.iconOnly)
    }
}

