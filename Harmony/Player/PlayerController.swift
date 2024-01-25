//
//  Player.swift
//  Harmony
//
//  Created by Claudio Cambra on 25/1/24.
//

import AVFoundation
import Foundation
import HarmonyKit

class PlayerController {
    static let shared = PlayerController()
    var avPlayer: AVPlayer?

    func playAsset(_ asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer?.play()
    }
}
