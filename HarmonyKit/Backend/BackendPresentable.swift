//
//  BackendPresentable.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 26/1/24.
//

import Combine
import Foundation

public class BackendPresentable: ObservableObject {
    @Published public var systemImage: String = "externaldrive.fill.badge.questionmark"
    @Published public var primary: String = ""
    @Published public var secondary: String = ""
    @Published public var config: String = "Not configured"
    @Published public var state: String = "Idle"

    public init(primary: String, secondary: String) {
        self.primary = primary
        self.secondary = secondary
    }
}
