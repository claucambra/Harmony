//
//  DetailColumn.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import HarmonyKit
import SwiftUI

struct DetailColumn: View {
    @Binding var selection: Panel?

    var body: some View {
        switch selection ?? .songs {
        case .songs:
            SongsTable(
                model: SongsModel(withBackends: BackendsModel.shared.backends),
                selection: .constant([])
            )
        }
    }
}

struct DetailColumn_Previews: PreviewProvider {
    struct Preview: View {
        @State private var selection: Panel? = .songs

        var body: some View {
            DetailColumn(selection: $selection)
        }
    }
    static var previews: some View {
        Preview()
    }
}
