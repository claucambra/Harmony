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

    private init() {
        let db = realm
        let dbPath = db.configuration.fileURL?.path ?? "unknown"
        Logger.database.info("Started database manager with db: \(dbPath)")
    }

    func writeSong(_ song: Song) {
        let dbSong = DatabaseSong(fromSong: song)
        do {
            try realm.write {
                realm.add(dbSong, update: .modified)
            }
        } catch let error {
            Logger.database.error("Error writing song to database: \(error)")
        }
    }

    func writeSongs(_ songs: [Song]) {
        let dbSongs = DatabaseSong.fromSongs(songs)
        do {
            try realm.write {
                realm.add(dbSongs, update: .modified)
            }
        } catch let error {
            Logger.database.error("Error writing songs to database: \(error)")
        }
    }
}
