//
//  BackendChoiceListItemView.swift
//  Harmony
//
//  Created by Claudio Cambra on 20/1/24.
//

import HarmonyKit
import SwiftUI

struct BackendChoiceListItemView: View {
    let backendDescription: BackendDescription
    @Binding var selection: BackendDescription?

    var body: some View {
        HStack {
            Image(systemName: backendDescription.systemImageName)
            VStack(alignment: .leading) {
                Text(backendDescription.name).fontWeight(.bold)
                Text(backendDescription.description)
            }
        }
    }
}
