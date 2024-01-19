//
//  Logger.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 18/1/24.
//

import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let defaultLog = Logger(subsystem: subsystem, category: "defaultLog")
}
