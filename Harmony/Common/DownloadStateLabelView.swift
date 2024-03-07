//
//  DownloadStateLabelView.swift
//  Harmony
//
//  Created by Claudio Cambra on 7/3/24.
//

import SwiftUI

struct DownloadStateLabelView: View {
    @State var downloaded: Bool
    
    var body: some View {
        Label(
            downloaded ? "Available offline" : "Available online only",
            systemImage: downloaded ? "arrow.down.circle.fill" : "cloud"
        )
        .labelStyle(.iconOnly)
    }
}
