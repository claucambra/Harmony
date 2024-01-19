//
//  Song.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import AVFoundation
import OSLog

public class Song {
    var identifier: String
    var title: String?
    var artist: String?
    var album: String?
    var genre: String?
    var creator: String?
    var subject: String?
    var contributor: String?
    var type: String?
    var duration: CMTime?

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
