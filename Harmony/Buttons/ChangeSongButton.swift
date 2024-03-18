//
//  PreviousSongButton.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct ChangeSongButton: View {
    enum ChangeType { case previous, next }
    @ObservedObject var controller = PlayerController.shared
    let buttonChangeType: ChangeType

    var body: some View {
        Button {
            switch buttonChangeType {
            case .previous:
                controller.playPreviousSong()
            case .next:
                controller.playNextSong()
            }
        } label: {
            switch buttonChangeType {
            case .previous:
                Label("Previous", systemImage: "backward.fill")
            case .next:
                Label("Next", systemImage: "forward.fill")
            }
        }
        .labelStyle(.iconOnly)
    }
}
