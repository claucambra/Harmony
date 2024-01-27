//
//  Song.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import AVFoundation
import OSLog

public typealias SongAssetProviderClosure = (Song) -> AVAsset

public class Song: Identifiable, Hashable {
    public static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public var identifier: String
    public var backendId: String
    public var url: URL
    public var title: String = ""
    public var artist: String = ""
    public var album: String = ""
    public var genre: String = ""
    public var creator: String = ""
    public var subject: String = ""
    public var contributor: String = ""
    public var type: String = ""
    public var duration: CMTime
    public var asset: AVAsset {
        get {
            if internalAsset == nil {
                internalAsset = assetProviderClosure!(self)
            }
            return internalAsset!
        }
    }
    private var internalAsset: AVAsset?
    private var assetProviderClosure: SongAssetProviderClosure?

    public init?(url: URL, asset: AVAsset, identifier: String, backendId: String) async {
        self.url = url
        self.internalAsset = asset
        self.identifier = identifier
        self.backendId = backendId

        title = url.lastPathComponent

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
                creator = value ?? ""
            } else if item.commonKey == .commonKeySubject {
                subject = value ?? ""
            } else if item.commonKey == .commonKeyContributor {
                contributor = value ?? ""
            } else if item.commonKey == .commonKeyType {
                type = value ?? ""
            }
        }

        do {
            duration = try await asset.load(.duration)
        } catch {
            duration = CMTime(seconds: 0, preferredTimescale: 44100)
        }
    }

    public init(
        identifier: String,
        backendId: String,
        url: URL,
        title: String = "",
        artist: String = "",
        album: String = "",
        genre: String = "",
        creator: String = "",
        subject: String = "",
        contributor: String = "",
        type: String = "",
        duration: CMTime,
        assetProviderClosure: @escaping SongAssetProviderClosure
    ) {
        self.identifier = identifier
        self.backendId = backendId
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.genre = genre
        self.creator = creator
        self.subject = subject
        self.contributor = contributor
        self.type = type
        self.duration = duration
        self.assetProviderClosure = assetProviderClosure
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
