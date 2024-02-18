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

// TODO: Implement artwork when loading from database
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
    public private(set) var peformer: String = ""
    public private(set) var duration: TimeInterval = 0
    @Attribute(.externalStorage) public var artwork: Data?

    // Used by the backends during scanning, initial creation that sets all values received
    public init?(url: URL, asset: AVAsset, identifier: String, backendId: String) async {
        self.url = url
        self.identifier = identifier
        self.backendId = backendId

        title = url.lastPathComponent

        do {
            duration = try await asset.load(.duration).seconds
        } catch let error {
            Logger.defaultLog.error("Could not get duration for song \(url): \(error)")
        }

        await setupArtwork(asset: asset)

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
                    composer = value ?? ""
                } else if key == AVMetadataKey.commonKeySubject.rawValue {
                    grouping = value ?? ""
                } else if key == AVMetadataKey.commonKeyContributor.rawValue {
                    peformer = value ?? ""
                } else if key == AVMetadataKey.commonKeyType.rawValue {
                    genre = value ?? ""
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
                composer = value ?? ""
            } else if item.commonKey == .commonKeySubject {
                grouping = value ?? ""
            } else if item.commonKey == .commonKeyContributor {
                peformer = value ?? ""
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
        artwork: Data?
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
        self.peformer = peformer
        self.duration = duration
        self.artwork = artwork
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
            peformer: peformer,
            duration: duration,
            artwork: artwork
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
