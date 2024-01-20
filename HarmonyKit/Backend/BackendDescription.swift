//
//  BackendDescription.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 20/1/24.
//

import Foundation

public struct BackendDescription: Hashable, Identifiable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let systemImageName: String
}
