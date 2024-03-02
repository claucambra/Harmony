//
//  Song.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import Alamofire
import AVFoundation
import OSLog
import SwiftData

@Model
public final class Song: ObservableObject {
    @Attribute(.unique) public let identifier: String
    public let backendId: String
    public let url: URL
    public var isPlayNext = false
    public private(set) var title: String = ""
    public private(set) var artist: String = ""
    public private(set) var album: String = ""
    public private(set) var genre: String = ""
    public private(set) var composer: String = ""
    public private(set) var grouping: String = ""
    public private(set) var performer: String = ""
    public private(set) var duration: TimeInterval = 0
    public private(set) var year: Int = 0
    public private(set) var trackNumber: Int = 0
    public private(set) var discNumber: Int = 1
    public private(set) var discTotal: Int = 1
    public private(set) var parentAlbum: Album?
    @Attribute(.externalStorage) public var artwork: Data?
    public internal(set) var local: Bool = false
    public internal(set) var downloaded: Bool = false
    public internal(set) var versionId: String = ""

    // Used by the backends during scanning, initial creation that sets all values received
    public init?(
        url: URL,
        asset: AVAsset,
        identifier: String,
        backendId: String,
        local: Bool = false,
        downloaded: Bool = false,
        versionId: String = "",
        fetchSession: Alamofire.Session? = nil,
        fetchHeaders: HTTPHeaders? = nil
    ) async {
        self.url = url
        self.identifier = identifier
        self.backendId = backendId
        self.local = local
        self.downloaded = downloaded
        self.versionId = versionId

        title = url.lastPathComponent

        do {
            duration = try await asset.load(.duration).seconds
        } catch let error {
            Logger.defaultLog.error("Could not get duration for song \(url): \(error)")
        }

        await setupArtwork(asset: asset)

        guard !url.lastPathComponent.contains(".flac") else {
            if url.isFileURL {
                ingestLocalFlacProperties()
            } else if let fetchSession = fetchSession {
                await ingestRemoteFlacProperties(session: fetchSession, headers: fetchHeaders)
            } else {
                Logger.defaultLog.log("Cannot fetch remote flac metadata.")
            }
            return
        }

        guard let metadata = try? await asset.load(.commonMetadata) else {
            Logger.defaultLog.log("Could not get metadata for asset \(asset)")
            return nil
        }

        for item in metadata {
            let value = try? await item.load(.stringValue)
            if item.commonKey == .commonKeyTitle {
                title = value ?? ""
            } else if item.commonKey == .commonKeyAlbumName {
                album = value ?? ""
            } else if item.commonKey == .commonKeyArtist {
                artist = value ?? ""
            } else if item.commonKey == .commonKeyCreator {
                composer = value ?? ""
            } else if item.commonKey == .commonKeySubject {
                grouping = value ?? ""
            } else if item.commonKey == .commonKeyContributor {
                performer = value ?? ""
            } else if item.commonKey == .commonKeyType {
                genre = value ?? ""
            }
        }
    }

    private init(
        identifier: String,
        backendId: String,
        url: URL,
        title: String,
        artist: String,
        album: String,
        genre: String,
        composer: String,
        grouping: String,
        peformer: String,
        duration: TimeInterval,
        artwork: Data?,
        local: Bool = false,
        downloaded: Bool = false,
        versionId: String = ""
    ) {
        self.identifier = identifier
        self.backendId = backendId
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.genre = genre
        self.composer = composer
        self.grouping = grouping
        self.performer = peformer
        self.duration = duration
        self.artwork = artwork
        self.local = local
        self.downloaded = downloaded
        self.versionId = versionId
    }

    public func clone() -> Song {
        return Song(
            identifier: identifier,
            backendId: backendId,
            url: url,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            composer: composer,
            grouping: grouping,
            peformer: performer,
            duration: duration,
            artwork: artwork,
            local: local,
            downloaded: downloaded,
            versionId: versionId
        )
    }

    private func setupArtwork(asset: AVAsset) async {
        guard let metadata = try? await asset.load(.metadata) else { return }
        guard let artworkItem = AVMetadataItem.metadataItems(
            from: metadata,
            filteredByIdentifier: .commonIdentifierArtwork
        ).first else { return }
        guard let artworkData = try? await artworkItem.load(.value) as? Data else { return }

        Task { @MainActor in
            artwork = artworkData
        }
    }

    private func ingestLocalFlacProperties() {
        do {
            let flacData = try Data(contentsOf: url)
            let flacParser = FLACParser(data: flacData)
            let flacMetadata = try flacParser.parse()
            ingest(flacMetadata: flacMetadata)
        } catch let error {
            Logger.defaultLog.error("Could not ingest local flac properties: \(error)")
        }
    }

    private func ingestRemoteFlacProperties(
        session: Alamofire.Session, headers: HTTPHeaders?
    ) async {
        let fetcher = FLACRemoteMetadataFetcher(url: url, session: session, headers: headers)
        guard let metadata = await fetcher.fetch() else {
            Logger.defaultLog.error("Fetching remote FLAC metadata failed. \(self.url)")
            return
        }
        ingest(flacMetadata: metadata)
    }

    private func ingest(flacMetadata: FLACMetadata) {
        guard let metadataDict = flacMetadata.vorbisComments?.metadata else {
            Logger.defaultLog.error("Could not retrieve FLAC metadata. \(self.url)")
            return
        }

        let field = FLACVorbisCommentsMetadataBlock.Field.self
        title = metadataDict[field.title] ?? ""
        album = metadataDict[field.album] ?? ""
        artist = metadataDict[field.artist] ?? ""
        genre = metadataDict[field.genre] ?? ""
        performer = metadataDict[field.performer] ?? ""
        year = Int(metadataDict[field.year] ?? "") ?? 0
        trackNumber = Int(metadataDict[field.trackNumber] ?? "") ?? 0
        discNumber = Int(metadataDict[field.discNumber] ?? "") ?? 1
        discTotal = Int(metadataDict[field.discTotal] ?? "") ?? 1
        artwork = flacMetadata.picture?.data
    }
}
