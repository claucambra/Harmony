//
//  Song.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import AVFoundation
import OSLog

public class Song: Identifiable {
    public var identifier: String
    public var title: String = ""
    public var artist: String = ""
    public var album: String = ""
    public var genre: String = ""
    public var creator: String = ""
    public var subject: String = ""
    public var contributor: String = ""
    public var type: String = ""
    public var duration: CMTime?

    public init?(fromAsset asset: AVAsset, withIdentifier id: String) async {
        guard let metadata = try? await asset.load(.commonMetadata) else {
            Logger.defaultLog.log("Could not get metadata for asset \(asset)")
            return nil
        }

        for item in metadata {
            if let value = try? await item.load(.value) as? String {
                switch item.commonKey?.rawValue {
                case "title":
                    title = value
                    break
                case "albumName":
                    album = value
                    break
                case "artist":
                    artist = value
                    break
                case "creator":
                    creator = value
                    break
                case "subject":
                    subject = value
                    break
                case "contributor":
                    contributor = value
                    break
                case "type":
                    type = value
                    break
                default:
                    break
                }
            }
        }

        identifier = id
        duration = try? await asset.load(.duration)
    }
}
