//
//  EnvironmentValues+Extension.swift
//  Harmony
//
//  Created by Claudio Cambra on 3/2/24.
//

import SwiftUI

private struct FloatingBarHeightEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0.0
}

private struct SearchTextEnvironmentKey: EnvironmentKey {
    static let defaultValue: String = ""
}

extension EnvironmentValues {
    var floatingBarHeight: CGFloat {
        get { self[FloatingBarHeightEnvironmentKey.self] }
        set { self[FloatingBarHeightEnvironmentKey.self] = newValue }
    }
    var searchText: String {
        get { self[SearchTextEnvironmentKey.self] }
        set { self[SearchTextEnvironmentKey.self] = newValue }
    }
}
