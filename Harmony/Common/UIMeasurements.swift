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

struct UIMeasurements {
    static let smallPadding = 5.0
    static let mediumPadding = 10.0
    static let largePadding = 20.0
    static let veryLargePadding = 40.0

    static let smallCornerRadius = 2.5
    static let cornerRadius = 5.0
    static let largeCornerRadius = 10.0

    static let thinBorderWidth = 1.0

    static let shadowRadius = 4.0

    static let mediumButtonSize = 40.0
    static let mediumButtonSymbolFontSize = 24.0
    static let largeButtonSymbolFontSize = 32.0

    static let smallArtworkHeight = 48.0
    static let mediumArtworkHeight = 64.0
    static let largeArtworkHeight = 300.0

    static let smallWindowWidth = 320.0
    static let smallWindowHeight = 240.0

    static let mediumWindowWidth = 640.0
    static let mediumWindowHeight = 480.0

    static let toolbarCurrentSongViewWidth = 320.0

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
