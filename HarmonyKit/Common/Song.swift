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

        do {
            duration = try await asset.load(.duration)
        } catch {
            duration = CMTime(seconds: 0, preferredTimescale: 44100)
        }

        guard !url.lastPathComponent.contains(".flac") else {
            // TODO: What do when these are remote?
            Logger.defaultLog.debug("Custom handling for flac: \(url)")
            let flacMetadataTask =  Task {
                var fileId: AudioFileID? = nil
                var status: OSStatus = AudioFileOpenURL(
                    url as CFURL, .readPermission, kAudioFileFLACType, &fileId
                )
                guard let audioFile = fileId else { return }

                var dict: CFDictionary? = nil
                var dataSize = UInt32(MemoryLayout<CFDictionary?>.size(ofValue: dict))

                status = AudioFileGetProperty(audioFile, kAudioFilePropertyInfoDictionary, &dataSize, &dict)
                guard status == noErr else { return }

                AudioFileClose(audioFile)

                guard let cfDict = dict else { return }
                let tagsDict = NSDictionary(dictionary: cfDict)
                for (key, value) in tagsDict {
                    let key = key as? String ?? ""
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
            _ = await flacMetadataTask.result
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
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
