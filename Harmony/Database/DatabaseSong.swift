//
//  DatabaseSong.swift
//  Harmony
//
//  Created by Claudio Cambra on 27/1/24.
//

import AVFoundation
import Foundation
import HarmonyKit
import OSLog
import RealmSwift

class DatabaseSong: Object {
    @Persisted var identifier: String  // Unique identifier provided by backend
    @Persisted var backendId: String
    @Persisted var url: String
    @Persisted var title: String = ""
    @Persisted var artist: String = ""
    @Persisted var album: String = ""
    @Persisted var genre: String = ""
    @Persisted var creator: String = ""
    @Persisted var subject: String = ""
    @Persisted var contributor: String = ""
    @Persisted var type: String = ""
    @Persisted var duration: TimeInterval = 0  // Seconds

    init(fromSong song: Song) {
        identifier = song.identifier
        title = song.title
        artist = song.artist
        album = song.album
        genre = song.genre
        creator = song.creator
        subject = song.subject
        contributor = song.contributor
        type = song.type
        duration = song.duration.seconds
    }

    func toSong() async -> Song? {
        guard let actualUrl = URL(string: url) else {
            Logger.database.error("Could not create URL from stored url \(self.url)")
            return nil
        }
        guard let asset = BackendsModel.shared.assetForSong(
            atURL: actualUrl, backendId: backendId
        ) else {
            Logger.database.error("Could not get asset for song at \(self.url)")
            return nil
        }
        return await Song(url: actualUrl, asset: asset, identifier: identifier, backendId: backendId)
    }
}