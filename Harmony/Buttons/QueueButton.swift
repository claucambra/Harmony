//
//  QueueButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct QueueButton: View {
    @Binding var queueVisible: Bool

    var body: some View {
        Button {
            queueVisible = !queueVisible
        } label: {
            Label("Open queue", systemImage: "list.triangle")
        }
    }
}

