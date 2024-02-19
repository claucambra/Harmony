//
//  LoadingIndicatorOverlayView.swift
//  Harmony
//
//  Created by Claudio Cambra on 19/2/24.
//

import SwiftUI

struct LoadingIndicatorOverlayView: View {
    var topLeadingRadius: CGFloat = UIMeasurements.cornerRadius
    var bottomLeadingRadius: CGFloat = UIMeasurements.cornerRadius
    var bottomTrailingRadius: CGFloat = UIMeasurements.cornerRadius
    var topTrailingRadius: CGFloat = UIMeasurements.cornerRadius

    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .foregroundStyle(.regularMaterial)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(.rect(cornerRadii: .init(
                    topLeading: topLeadingRadius,
                    bottomLeading: bottomLeadingRadius,
                    bottomTrailing: bottomTrailingRadius,
                    topTrailing: topTrailingRadius
                )))
            ProgressView()
                .padding(.all, UIMeasurements.mediumPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
