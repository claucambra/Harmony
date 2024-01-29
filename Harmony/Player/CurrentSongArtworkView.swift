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
        if let imageData = controller.currentSong?.artwork {
            #if os(macOS)
            if let image = NSImage(data: imageData) {
                adjustedImage(Image(nsImage: image))
            }
            #else
            if let image = UIImage(data: imageData) {
                adjustedImage(Image(uiImage: image))
            }
            #endif
        } else {
            ZStack(alignment: .center) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                adjustedImage(Image(systemName: "music.note"))
                    .padding(5.0)
            }
        }
    }

    @ViewBuilder
    func adjustedImage(_ image: Image) -> some View {
        image
            .interpolation(.high)
            .resizable()
            .scaledToFit()
            .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
    }
}

#Preview {
    PlayerCurrentSongView()
}
