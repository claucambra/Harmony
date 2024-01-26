//
//  Logger.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/1/24.
//

import OSLog

extension Logger {
    static var subsystem = Bundle.main.bundleIdentifier!
    static let config = Logger(subsystem: subsystem, category: "config")
    static let player = Logger(subsystem: subsystem, category: "player")
}
