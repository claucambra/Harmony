//
//  DatabaseManager.swift
//  Harmony
//
//  Created by Claudio Cambra on 27/1/24.
//

import Foundation
import HarmonyKit
import RealmSwift
import OSLog

@MainActor
class DatabaseManager {
    static let shared = DatabaseManager()
    private var realm: Realm {
        get {
            let db = try! Realm()
            db.refresh()
            return db
        }
    }
}
