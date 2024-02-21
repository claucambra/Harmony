//
//  FLACParser.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

class FLACParser {
    let data: Data

    var isFLAC: Bool {
        String(data: data[0..<4], encoding: .ascii) == FLACMetadata.streamMarker
    }

    init(data: Data) {
        self.data = data
    }
}

