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

    func artworkData() async throws -> Data? {
        if let amArtwork = artwork, let amArtworkUrl = amArtwork.url(width: 1024, height: 1024) {
            let urlRequest = URLRequest(url: amArtworkUrl)
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            return data
        }
        return nil
    }

    func toHarmonySong(backendId: String) async -> Song {
        var harmonyYear = 0
        if let amDate = releaseDate,
           let amYear = Calendar.current.dateComponents([.year], from: amDate).year
        {
            harmonyYear = amYear
        }
        var harmonyArtwork: Data? = nil
        do {
            harmonyArtwork = try await artworkData()
        } catch let error {
            logger.error("Failed to retrive artwork data for \(title): \(error)")
        }
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

public class AppleMusicBackend: NSObject {
    private let logger: Logger = Logger(subsystem: Logger.subsystem, category: "AppleMusic")

    public func appleMusicSong(id: String) async -> MusicKit.Song? {
        let appleMusicId = MusicItemID(id)
        var request = MusicLibraryRequest<MusicKit.Song>()
        request.filter(matching: \.id, equalTo: appleMusicId)
        do {
            let response = try await request.response()
            return response.items.first
        } catch let error {
            logger.error("Error getting Apple Music song from ID: \(error)")
            return nil
        }
    }
}
