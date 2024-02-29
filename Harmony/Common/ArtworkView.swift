//
//  ArtworkView.swift
//  Harmony
//
//  Created by Claudio Cambra on 29/2/24.
//

import SwiftUI

struct ArtworkView: View {
    enum ScaleMode { case fill, fit }
    let artwork: Data?
    @State var scaleMode: ScaleMode = .fit

    var body: some View {
        if let imageData = artwork {
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
            PlaceholderArtworkView()
        }
    }

    @ViewBuilder
    func adjustedImage(_ image: Image) -> some View {
        let image = image
            .interpolation(.high)
            .resizable()
            .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)

        switch scaleMode {
        case .fill:
            image.scaledToFill()
        case .fit:
            image.scaledToFit()
        }
    }
}

