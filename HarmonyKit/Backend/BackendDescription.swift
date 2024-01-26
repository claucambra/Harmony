//
//  BackendDescription.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 20/1/24.
//

import Foundation

public typealias BackendConfiguration = [String: Any]

public enum BackendConfigurationValueType {
    case bool, int, float, string, localUrl
}

public struct BackendConfigurationField: Hashable, Identifiable {
    public static func == (lhs: BackendConfigurationField, rhs: BackendConfigurationField) -> Bool {
        return lhs.id == rhs.id
    }
    
    public let id: String
    public let title: String
    public let description: String
    public let valueType: BackendConfigurationValueType
    public let isArray: Bool
    public let optional: Bool
    public let defaultValue: Any

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public typealias BackendConfigurationDescription = [BackendConfigurationField]

public struct BackendDescription: Hashable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let systemImageName: String
    public let configDescription: BackendConfigurationDescription
}

#if os(macOS)
public let BackendConfigurationLocalURLAccessibleURLFieldKeySuffix = "__accessible-url"
#endif
