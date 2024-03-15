//
//  Container.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 14/3/24.
//

import SwiftData

@Model
final public class Container {
    @Attribute(.unique) public var identifier = ""
    public var versionId = ""

    init(identifier: String = "", versionId: String = "") {
        self.identifier = identifier
        self.versionId = versionId
    }
}
