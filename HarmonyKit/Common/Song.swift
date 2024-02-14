//
//  Song.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import AVFoundation
import OSLog
import SwiftData

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@Model
public final class Song: Identifiable, Hashable {
    public static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.identifier == rhs.identifier
    }

    @Attribute(.unique) public let identifier: String
    public let backendId: String
    public let url: URL
    public var isPlayNext = false
    public private(set) var title: String = ""
    public private(set) var artist: String = ""
    public private(set) var album: String = ""
    public private(set) var genre: String = ""
    public private(set) var creator: String = ""
    public private(set) var subject: String = ""
    public private(set) var contributor: String = ""
    public private(set) var type: String = ""
    public private(set) var duration: TimeInterval = 0
    public private(set) var artwork: Data?
    @Transient public var asset: AVAsset {
        get { internalAsset ?? AVAsset(url: url) }
    }
    @Transient private var internalAsset: AVAsset?

    public init?(url: URL, asset: AVAsset, identifier: String, backendId: String) async {
        self.url = url
        self.internalAsset = asset
        self.identifier = identifier
        self.backendId = backendId

        title = url.lastPathComponent

        do {
            duration = try await asset.load(.duration).seconds
        } catch let error {
            Logger.defaultLog.error("Could not get duration for song \(url): \(error)")
        }

        await setupArtwork()

        guard !url.lastPathComponent.contains(".flac") else {
            let tagsDict = audioFileMetadata()
            for (key, value) in tagsDict {
                let key = key as? String ?? ""
                if key == AVMetadataKey.commonKeyArtwork.rawValue {
                    artwork = value as? Data ?? Data()
                    continue
                }

                let value = value as? String
                if key == AVMetadataKey.commonKeyTitle.rawValue {
                    title = value ?? ""
                } else if key == AVMetadataKey.commonKeyAlbumName.rawValue || key == "album" {
                    album = value ?? ""
                } else if key == AVMetadataKey.commonKeyArtist.rawValue {
                    artist = value ?? ""
                } else if key == AVMetadataKey.commonKeyCreator.rawValue {
                    creator = value ?? ""
                } else if key == AVMetadataKey.commonKeySubject.rawValue {
                    subject = value ?? ""
                } else if key == AVMetadataKey.commonKeyContributor.rawValue {
                    contributor = value ?? ""
                } else if key == AVMetadataKey.commonKeyType.rawValue {
                    type = value ?? ""
                }
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
                creator = value ?? ""
            } else if item.commonKey == .commonKeySubject {
                subject = value ?? ""
            } else if item.commonKey == .commonKeyContributor {
                contributor = value ?? ""
            } else if item.commonKey == .commonKeyType {
                type = value ?? ""
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
        creator: String,
        subject: String,
        contributor: String,
        type: String,
        duration: TimeInterval,
        asset: AVAsset
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
        self.internalAsset = asset

        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await setupArtwork()
            semaphore.signal()
        }
        semaphore.wait()
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
            creator: creator,
            subject: subject,
            contributor: contributor,
            type: type,
            duration: duration,
            asset: asset
        )
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    private func setupArtwork() async {
        guard let metadata = try? await asset.load(.metadata) else { return }
        guard let artworkItem = AVMetadataItem.metadataItems(
            from: metadata,
            filteredByIdentifier: .commonIdentifierArtwork
        ).first else { return }
        guard let artworkData = try? await artworkItem.load(.value) as? Data else { return }

        artwork = artworkData
    }

    private func audioFileMetadata() -> NSDictionary {
        // TODO: What do when url is remote?
        var fileId: AudioFileID? = nil
        var status: OSStatus = AudioFileOpenURL(
            url as CFURL, .readPermission, kAudioFileFLACType, &fileId
        )
        guard let audioFile = fileId else { return NSDictionary() }

        var dict: CFDictionary? = nil
        var dataSize = UInt32(MemoryLayout<CFDictionary?>.size(ofValue: dict))

        status = AudioFileGetProperty(audioFile, kAudioFilePropertyInfoDictionary, &dataSize, &dict)
        guard status == noErr else { return NSDictionary() }

        AudioFileClose(audioFile)

        guard let cfDict = dict else { return NSDictionary() }
        return NSDictionary(dictionary: cfDict)
    }
}
