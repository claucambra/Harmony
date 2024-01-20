//
//  AVAsset+Extension.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 19/1/24.
//

import AVFoundation
import OSLog

extension AVAsset {
    public static func assetsFromURLs(_ urls: [URL]) async -> [AVAsset] {
        var assets: [AVAsset] = []
        for url in urls {
            let asset = AVAsset(url: url)
            let isPlayable = try? await !asset.load(.isPlayable)
            if isPlayable == nil || isPlayable! == false {
                Logger.defaultLog.warning("URL \(url) is not playable. Not adding to assets array.")
            } else {
                assets.append(asset)
            }
        }
        return assets
    }
}
