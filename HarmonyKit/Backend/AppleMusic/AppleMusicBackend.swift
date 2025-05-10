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

public class AppleMusicBackend: NSObject, Backend {
    public let typeDescription = appleMusicBackendTypeDescription
    public let backendId: String
    public var presentation: BackendPresentable
    public var configValues: BackendConfiguration
    public let player = AppleMusicPlayer() as any BackendPlayer

    private let logger: Logger

    public required init(config: BackendConfiguration) {
        configValues = config
        backendId = config[BackendConfigurationIdFieldKey] as! String
        presentation = BackendPresentable(
            backendId: backendId,
            typeId: appleMusicBackendTypeDescription.id,
            systemImage: appleMusicBackendTypeDescription.systemImageName,
            primary: appleMusicBackendTypeDescription.name,
            secondary: appleMusicBackendTypeDescription.description,
            config: "Automatically available."
        )
        logger = Logger(subsystem: Logger.subsystem, category: backendId)

        super.init()

        (player as! AppleMusicPlayer).backend = self
        Task { await requestAuthorization() }
    }

    func requestAuthorization() async -> MusicAuthorization.Status {
        guard MusicAuthorization.currentStatus != .authorized else { return .authorized }
        return await MusicAuthorization.request()
    }

    public func scan(
        containerScanApprover: @Sendable @escaping (
            _ containerId: String, _ versionId: String
        ) async -> Bool,
        songScanApprover: @escaping @Sendable (String, String) async -> Bool,
        finalisedSongHandler: @escaping @Sendable (Song) async -> Void,
        finalisedContainerHandler: @escaping @Sendable (Container, Container?) async -> Void
    ) async throws {
        let currentScanDate = Date().description
        let appleMusicContainer = Container(
            identifier: self.backendId, backendId: self.backendId, versionId: currentScanDate
        )
        guard await containerScanApprover(appleMusicContainer.identifier, currentScanDate) else {
            logger.debug("Container scan denied. This should not happen!")
            return
        }

        let request = MusicLibraryRequest<MusicKit.Song>()
        let response = try await request.response()

        for appleMusicSong in response.items {
            guard await songScanApprover(appleMusicSong.id.rawValue, "0") else { continue }
            let harmonySong = await appleMusicSong.toHarmonySong(backendId: backendId)
            await finalisedSongHandler(harmonySong)
        }
        await finalisedContainerHandler(appleMusicContainer, nil)
    }

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

    public func appleMusicSongSynchronous(id: String) -> MusicKit.Song? {
        let semaphore = DispatchSemaphore(value: 0)
        var appleMusicSong: MusicKit.Song?
        Task {
            appleMusicSong = await self.appleMusicSong(id: id)
            semaphore.signal()
        }
        semaphore.wait()
        return appleMusicSong
    }

    public func harmonySongFromId(_ id: String) -> Song? {
        guard let appleMusicSong = appleMusicSongSynchronous(id: id) else { return nil }
        let semaphore = DispatchSemaphore(value: 0)
        var harmonySong: Song?
        Task {
            harmonySong = await appleMusicSong.toHarmonySong(backendId: backendId)
            semaphore.signal()
        }
        semaphore.wait()
        return harmonySong
    }

    public func cancelScan() {
        return // TODO
    }

    public func assetForSong(_ song: Song) -> AVAsset? {
        return nil
    }

    public func fetchSong(_ song: Song) async {
        return
    }

    public func evictSong(_ song: Song) async {
        return
    }
}
