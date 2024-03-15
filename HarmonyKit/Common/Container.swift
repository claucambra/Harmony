//
//  Container.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 14/3/24.
//

import SwiftData

/// Containers, which hold metadata for structures like folders, exist purely for scanning purposes.
/// When dealing with file hierarchies, knowing the state of a given container can help speed up
/// scan times significantly, as knowing the versionId of a container can sometimes help in knowing
/// whether a given container needs to be scanned or not. In cases where knowing about the container
/// state is not possible or not useful, backends can safely ignore them.

@Model
final public class Container {
    @Attribute(.unique) public let identifier: String
    public let backendId: String
    public let versionId: String
    public var parentContainer: Container?
    @Relationship(
        deleteRule: .cascade, inverse: \Container.parentContainer
    ) public var childContainers: [Container] = []

    init(
        identifier: String,
        backendId: String,
        versionId: String,
        parentContainer: Container?,
        childContainers: [Container] = []
    ) {
        self.identifier = identifier
        self.backendId = backendId
        self.versionId = versionId
        self.parentContainer = parentContainer
        self.childContainers = childContainers
    }
}
