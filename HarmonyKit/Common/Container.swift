//
//  Container.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 14/3/24.
//

import SwiftData

@Model
final public class Container {
    var identifier = ""
    var versionId = ""

    init(identifier: String = "", versionId: String = "") {
        self.identifier = identifier
        self.versionId = versionId
    }
}
