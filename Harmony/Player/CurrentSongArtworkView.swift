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
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
            }
            #else
            if let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
            }
            #endif
        } else {
            ZStack(alignment: .center) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                    .padding(5.0)
            }
        }
    }
}

#Preview {
    PlayerCurrentSongView()
}
