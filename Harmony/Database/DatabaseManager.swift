//
//  DatabaseManager.swift
//  Harmony
//
//  Created by Claudio Cambra on 27/1/24.
//

import Foundation
import HarmonyKit
import OSLog
import SwiftData

@MainActor
class DatabaseManager {
    static let shared = DatabaseManager()
    private let songsContainer = try! ModelContainer(for: DatabaseSong.self)

    private init() {
        Logger.database.info("Started database manager")
    }

    func songs() async -> [Song] {
        let context = songsContainer.mainContext
        let songsQuery = FetchDescriptor<DatabaseSong>(predicate: #Predicate { _ in true })
        do {
            let results = try context.fetch(songsQuery)
            return await withTaskGroup(of: Song?.self, returning: [Song].self) { group in
                for result in results {
                    group.addTask {
                        return result.toSong()
                    }
                }

                var songs: [Song] = []
                for await result in group {
                    guard let song = result else { continue }
                    songs.append(song)
                }
                return songs
            }
        } catch let error {
            Logger.database.error("Failed to get songs: \(error)")
            return []
        }
    }

    func writeSong(_ song: Song) {
        let context = songsContainer.mainContext
        let dbSong = DatabaseSong(fromSong: song)
        context.insert(dbSong)
    }

    func writeSongs(_ songs: [Song]) {
        let context = songsContainer.mainContext
        let dbSongs = DatabaseSong.fromSongs(songs)
        for dbSong in dbSongs {
            context.insert(dbSong)
        }
    }
}
