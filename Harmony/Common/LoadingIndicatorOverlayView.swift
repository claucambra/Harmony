//
//  LoadingIndicatorOverlayView.swift
//  Harmony
//
//  Created by Claudio Cambra on 19/2/24.
//

import SwiftUI

struct LoadingIndicatorOverlayView: View {
    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: UIMeasurements.cornerRadius)
                .foregroundStyle(.thickMaterial)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            ProgressView()
                .padding(.all, UIMeasurements.mediumPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
