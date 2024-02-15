//
//  PlaceholderArtworkView.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/2/24.
//

import SwiftUI

struct PlaceholderArtworkView: View {
    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .foregroundStyle(.clear)
                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
            Image(systemName: "music.note")
                .interpolation(.high)
                .resizable()
                .scaledToFit()
                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                .padding(UIMeasurements.mediumPadding)
        }
    }
}
