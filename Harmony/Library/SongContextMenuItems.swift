//
//  SongContextMenuItems.swift
//  Harmony
//
//  Created by Claudio Cambra on 4/2/24.
//

import SwiftUI

struct SongContextMenuItems: View {
    @ObservedObject var queue = PlayerController.shared.queue
    let song: DatabaseSong

    var body: some View {
        Button {
            queue.insertNextSong(song)
        } label: {
            Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward")
        }
    }
}