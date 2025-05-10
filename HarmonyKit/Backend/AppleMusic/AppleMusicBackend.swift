//
//  AppleMusicBackend.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 10/5/25.
//

import AVFoundation
import MusicKit
import OSLog

extension MusicKit.Song {
    var logger: Logger { Logger(subsystem: Logger.subsystem, category: "MusicKitSongExtension") }

    func toHarmonySong(backendId: String) async -> Song {
        var harmonyYear = 0
        if let amDate = releaseDate,
           let amYear = Calendar.current.dateComponents([.year], from: amDate).year
        {
            harmonyYear = amYear
        }
        var harmonyArtwork: Data? = nil
        return Song(
            identifier: id.rawValue,
            parentContainerId: "AppleMusic",
            backendId: backendId,
            url: url ?? URL(fileURLWithPath: ""),
            title: title,
            artist: artistName,
            album: albumTitle ?? "",
            genre: genreNames.joined(separator: ", "),
            composer: composerName ?? "",
            duration: duration ?? 0,
            year: harmonyYear,
            trackNumber: trackNumber ?? 0,
            discNumber: discNumber ?? 0,
            parentAlbum: nil,
            parentArtists: [],
            artwork: harmonyArtwork,
            local: false,
            downloadState: .notDownloaded,
            downloadProgress: 0.0,
            versionId: "0"
        )
    }
}
