//
//  CurrentSongArtworkView.swift
//  Harmony
//
//  Created by Claudio Cambra on 29/1/24.
//

import SwiftUI

struct CurrentSongArtworkView: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        #if os(macOS)
        if let imageData = controller.currentSong?.artwork,
           let image = NSImage(data: imageData) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
        }
        #else
        if let imageData = controller.currentSong?.artwork,
           let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
        }
        #endif
    }
}

#Preview {
    PlayerCurrentSongView()
}
