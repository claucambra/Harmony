//
//  BorderedArtworkView.swift
//  Harmony
//
//  Created by Claudio Cambra on 29/2/24.
//

import SwiftUI

struct BorderedArtworkView: View {
    let artwork: Data?
    let borderWidth = UIMeasurements.thinBorderWidth
    let cornerRadius = UIMeasurements.cornerRadius
    let scaleMode = ArtworkView.ScaleMode.fit

    var body: some View {
        ArtworkView(artwork: artwork, scaleMode: scaleMode)
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.separator, lineWidth: borderWidth)
            )

    }
}
