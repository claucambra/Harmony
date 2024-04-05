//
//  BackendPresentable.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 26/1/24.
//

import Combine
import Foundation

public class BackendPresentable: ObservableObject, Hashable, Identifiable {
    public let backendId: String // The backend's id
    public let typeId: String
    @Published public var systemImage: String
    @Published public var primary: String
    @Published public var secondary: String
    @Published public var config: String
    @Published public var state: String
    @Published public var scanning: Bool

    public static func == (lhs: BackendPresentable, rhs: BackendPresentable) -> Bool {
        lhs.id == rhs.id
    }

    public init(
        backendId: String, 
        typeId: String,
        systemImage: String,
        primary: String,
        secondary: String,
        config: String = "Not configured",
        state: String = "Idle",
        scanning: Bool = false
    ) {
        self.backendId = backendId
        self.typeId = typeId
        self.systemImage = systemImage
        self.primary = primary
        self.secondary = secondary
        self.config = config
        self.state = state
        self.scanning = false
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(typeId)
        hasher.combine(systemImage)
        hasher.combine(primary)
        hasher.combine(secondary)
        hasher.combine(config)
        hasher.combine(state)
        hasher.combine(scanning)
    }
}
