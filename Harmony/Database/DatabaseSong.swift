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
import SwiftData

@Model
class DatabaseSong: Identifiable {
    @Attribute(.unique) var identifier: String  // Unique identifier provided by backend
    var backendId: String
    var url: String
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var genre: String = ""
    var creator: String = ""
    var subject: String = ""
    var contributor: String = ""
    var type: String = ""
    var duration: TimeInterval = 0  // Seconds
    var timeScale: Int32 = 1

    static func fromSongs(_ songs: [Song]) -> [DatabaseSong] {
        songs.map { DatabaseSong(fromSong: $0) }
    }

    init(identifier: String, backendId: String, url: String) {
        self.identifier = identifier
        self.backendId = backendId
        self.url = url
    }

    convenience init(fromSong song: Song) {
        self.init(
            identifier: song.identifier,
            backendId: song.backendId,
            url: song.url.absoluteString
        )

        title = song.title
        artist = song.artist
        album = song.album
        genre = song.genre
        creator = song.creator
        subject = song.subject
        contributor = song.contributor
        type = song.type
        duration = song.duration.seconds
        timeScale = song.duration.timescale
    }

    func toSong() -> Song? {
        guard let actualUrl = URL(string: url) else {
            Logger.database.error("Could not create URL from stored url \(self.url)")
            return nil
        }
        return Song(
            identifier: identifier,
            backendId: backendId,
            url: actualUrl,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            creator: creator,
            subject: subject,
            contributor: contributor,
            type: type,
            duration: CMTime(seconds: duration, preferredTimescale: timeScale),
            assetProviderClosure: { _ in
                return BackendsModel.shared.assetForSong(
                    atURL: actualUrl, backendId: self.backendId
                ) ?? AVAsset(url: actualUrl)
            }
        )
    }
}
