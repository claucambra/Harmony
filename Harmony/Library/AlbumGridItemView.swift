//
//  AlbumGridItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 29/2/24.
//

import HarmonyKit
import SwiftUI

struct AlbumGridItemView: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading) {
            Text(album.title)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity)
            Text(album.artist ?? "Unknown artist")
                .multilineTextAlignment(.leading)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }
}
