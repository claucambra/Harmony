//
//  EnvironmentValues+Extension.swift
//  Harmony
//
//  Created by Claudio Cambra on 3/2/24.
//

import SwiftUI

private struct SearchTextEnvironmentKey: EnvironmentKey {
    static let defaultValue: String = ""
}

extension EnvironmentValues {
    var searchText: String {
        get { self[SearchTextEnvironmentKey.self] }
        set { self[SearchTextEnvironmentKey.self] = newValue }
    }
}
