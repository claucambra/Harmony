//
//  Song.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import Alamofire
import AVFoundation
import FLACMetadataKit
import OSLog
import SwiftData

public enum DownloadState: Int {
    case notDownloaded, downloading, downloadedOutdated, downloaded
}

@Model
public final class Song: ObservableObject {
    @Attribute(.unique) public let identifier: String
    public let parentContainerId: String
    public let backendId: String
    public let url: URL
    @Transient public var isPlayNext = false
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
    public private(set) var parentArtists: [Artist] = []
    @Attribute(.externalStorage) public var artwork: Data?
    public internal(set) var local: Bool = false
    public var downloadState = DownloadState.notDownloaded.rawValue {
        didSet { parentAlbum?.updateDownloaded() }
    }
    @Transient public internal(set) var downloadProgress: Double = 0.0
    public internal(set) var versionId: String = ""

    // Used by the backends during scanning, initial creation that sets all values received
    public init?(
        url: URL,
        asset: AVAsset,
        identifier: String,
        parentContainerId: String,
        backendId: String,
        local: Bool = false,
        downloadState: DownloadState = .notDownloaded,
        versionId: String = "",
        fetchSession: Alamofire.Session? = nil,
        fetchHeaders: HTTPHeaders? = nil
    ) async {
        self.url = url
        self.identifier = identifier
        self.parentContainerId = parentContainerId
        self.backendId = backendId
        self.local = local
        self.downloadState = downloadState.rawValue
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

        // Now go for specific metadata
        guard let specificMetadataFormats = try? await asset.load(.availableMetadataFormats) else {
            Logger.defaultLog.log("Could not get available metadata formats for asset \(asset)")
            return
        }

        guard let metadataFormat = specificMetadataFormats.first else {
            Logger.defaultLog.log("Received no available metadata formats for asset \(asset)")
            return
        }

        guard let specificMetadata = try? await asset.loadMetadata(for: metadataFormat) else {
            Logger.defaultLog.log("Could not load specific metadata for asset \(asset)")
            return
        }

        switch(metadataFormat) {
        case .id3Metadata:
            for item in specificMetadata {
                guard let itemKey = item.key as? String else {
                    Logger.defaultLog.warning("Received unknown type of ID3 key")
                    continue
                }
                if itemKey.uppercased() == "TRCK" {
                    trackNumber = (try? await item.load(.numberValue) as? Int) ?? 1
                } else if itemKey.uppercased() == "TPOS" {
                    discNumber = (try? await item.load(.numberValue) as? Int) ?? 1
                    discTotal = discNumber
                } else if itemKey.uppercased() == "TYER" {
                    year = (try? await item.load(.numberValue) as? Int) ?? 0
                } else {
                    Logger.defaultLog.debug("Unknown ID3 tag \(itemKey) for song \(self.title)")
                }
            }
        default:
            return
        }
    }

    #if DEBUG
    init(
        identifier: String,
        parentContainerId: String = "parent",
        backendId: String = "backendId",
        url: URL = URL(string: "https://www.example.com")!,
        title: String = "",
        artist: String = "",
        album: String = "",
        genre: String = "",
        composer: String = "",
        grouping: String = "",
        performer: String = "",
        duration: TimeInterval = 0,
        year: Int = 0,
        trackNumber: Int = 1,
        discNumber: Int = 1,
        discTotal: Int = 1,
        parentAlbum: Album? = nil,
        parentArtists: [Artist] = [],
        artwork: Data? = nil,
        local: Bool = true,
        downloadState: DownloadState = .notDownloaded,
        downloadProgress: Double = 0.0,
        versionId: String = "0"
    ) {
        self.identifier = identifier
        self.parentContainerId = parentContainerId
        self.backendId = backendId
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.genre = genre
        self.composer = composer
        self.grouping = grouping
        self.performer = performer
        self.duration = duration
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.discTotal = discTotal
        self.parentAlbum = parentAlbum
        self.parentArtists = parentArtists
        self.artwork = artwork
        self.local = local
        self.downloadState = downloadState.rawValue
        self.downloadProgress = downloadProgress
        self.versionId = versionId
    }
    #endif

    private func setupArtwork(asset: AVAsset) async {
        guard let metadata = try? await asset.load(.metadata) else {
            Logger.defaultLog.error("Could not load metadata \(self.url)")
            return
        }
        guard let artworkItem = AVMetadataItem.metadataItems(
            from: metadata,
            filteredByIdentifier: .commonIdentifierArtwork
        ).first else {
            Logger.defaultLog.error("Could not load artwork \(self.url)")
            return
        }
        guard let artworkData = try? await artworkItem.load(.value) as? Data else {
            Logger.defaultLog.error("Could not load artowrk data \(self.url)")
            return
        }

        artwork = artworkData
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
