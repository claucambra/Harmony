//
//  UIMeasurements.swift
//  Harmony
//
//  Created by Claudio Cambra on 8/2/24.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import SwiftUI

struct UIMeasurements {
    static let smallPadding = 8.0
    static let mediumPadding = 12.0
    static let largePadding = 20.0
    static let veryLargePadding = 32.0
    static let ultraLargePadding = 48.0

    static let smallCornerRadius = 2.0
    static let cornerRadius = 4.0
    static let largeCornerRadius = 8.0

    static let thinBorderWidth = 1.0

    static let shadowRadius = 4.0

    static let smallBlurRadius = 4.0

    static let hoverOverlayOpacity = 0.4

    static let mediumButtonSize = 40.0
    static let mediumButtonSymbolFontSize = 24.0
    static let largeButtonSymbolFontSize = 32.0

    static let smallArtworkHeight = 48.0
    static let mediumArtworkHeight = 64.0
    static let mediumLargeArtworkHeight = 128.0
    static let largeArtworkHeight = 300.0

    static let smallWindowWidth = 320.0
    static let smallWindowHeight = 240.0

    static let mediumWindowWidth = 640.0
    static let mediumWindowHeight = 480.0

    static let toolbarCurrentSongViewWidth = 320.0

    static let tableColumnMiniWidth = 16.0

    static let hoverAnimation = Animation.linear(duration: 0.05)

    static var smallFontSize: CGFloat {
        get {
            #if os(macOS)
            NSFont.smallSystemFontSize
            #else
            UIFont.smallSystemFontSize
            #endif
        }
    }
}
