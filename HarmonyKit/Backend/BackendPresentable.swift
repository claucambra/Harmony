//
//  BackendPresentable.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 26/1/24.
//

import Combine
import Foundation

public class BackendPresentable: ObservableObject, Hashable, Identifiable {
    @Published public var id: String // The backend's id
    @Published public var typeId: String
    @Published public var systemImage: String
    @Published public var primary: String
    @Published public var secondary: String
    @Published public var config: String
    @Published public var state: String

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
        state: String = "Idle"
    ) {
        id = backendId
        self.typeId = typeId
        self.systemImage = systemImage
        self.primary = primary
        self.secondary = secondary
        self.config = config
        self.state = state
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(typeId)
        hasher.combine(systemImage)
        hasher.combine(primary)
        hasher.combine(secondary)
        hasher.combine(config)
        hasher.combine(state)
    }
}
