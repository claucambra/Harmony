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
    static let database = Logger(subsystem: subsystem, category: "database")
    static let player = Logger(subsystem: subsystem, category: "player")
    static let queue = Logger(subsystem: subsystem, category: "queue")
    static let songsTable = Logger(subsystem: subsystem, category: "songsTable")
    static let sync = Logger(subsystem: subsystem, category: "sync")
}
