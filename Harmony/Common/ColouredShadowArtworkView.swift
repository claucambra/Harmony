//
//  ColouredShadowArtworkView.swift
//  Harmony
//
//  Created by Claudio Cambra on 2/3/24.
//

import SwiftUI

struct ColouredShadowArtworkView: View {
    let artwork: Data?
    @State var borderWidth = UIMeasurements.thinBorderWidth
    @State var cornerRadius = UIMeasurements.cornerRadius
    @State var scaleMode = ArtworkView.ScaleMode.fit
    @State var shadowRadius = UIMeasurements.shadowRadius * 2
    @State var shadowOpacity = 0.6

    var body: some View {
        BorderedArtworkView(artwork: artwork, cornerRadius: cornerRadius, scaleMode: scaleMode)
            .background {
                BorderedArtworkView(artwork: artwork, scaleMode: scaleMode)
                    .blur(radius: shadowRadius)
                    .opacity(shadowOpacity)
            }
    }
}
