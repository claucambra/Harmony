//
//  Song.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import AVFoundation
import OSLog

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public typealias SongAssetProviderClosure = (Song) -> AVAsset

public class Song: Identifiable, Hashable {
    public static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public let instanceId: UUID = UUID()
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
    public var artwork: Data?
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

        do {
            duration = try await asset.load(.duration)
        } catch {
            duration = CMTime(seconds: 0, preferredTimescale: 44100)
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

        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await setupArtwork()
            semaphore.signal()
        }
        semaphore.wait()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    func setupArtwork() async {
        guard let metadata = try? await asset.load(.metadata) else { return }
        guard let artworkItem = AVMetadataItem.metadataItems(
            from: metadata,
            filteredByIdentifier: .commonIdentifierArtwork
        ).first else { return }
        guard let artworkData = try? await artworkItem.load(.value) as? Data else { return }

        artwork = artworkData
    }

    func audioFileMetadata() -> NSDictionary {
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
