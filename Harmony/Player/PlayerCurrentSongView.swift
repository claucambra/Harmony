//
//  PlayerCurrentSongView.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import SwiftUI

struct PlayerCurrentSongView: View {
    @ObservedObject var controller = PlayerController.shared

    var body: some View {
        HStack {
            HStack {
                #if os(macOS)
                if let imageData = controller.currentSong?.artwork,
                   let image = NSImage(data: imageData) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: .infinity)
                        .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                }
                #else
                if let imageData = controller.currentSong?.artwork,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                }
                #endif
                VStack {
                    Text(controller.currentSong?.title ?? "")
                        .frame(maxWidth: .infinity)
                    Text(controller.currentSong?.artist ?? "")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(width: 150)
    }
}

#Preview {
    PlayerCurrentSongView()
}
