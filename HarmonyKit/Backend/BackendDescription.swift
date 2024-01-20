//
//  BackendDescription.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 20/1/24.
//

import Foundation

public enum BackendConfigurationValueType {
    case bool, int, float, string
}

public struct BackendConfigurationField: Hashable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let valueType: BackendConfigurationValueType
    public let isArray: Bool
    public let optional: Bool
}

public typealias BackendConfigurationDescription = [BackendConfigurationField]

public struct BackendDescription: Hashable, Identifiable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let systemImageName: String
    public let configDescription: BackendConfigurationDescription
}
