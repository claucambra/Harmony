//
//  Player.swift
//  Harmony
//
//  Created by Claudio Cambra on 25/1/24.
//

import AVFoundation
import Foundation
import HarmonyKit

class PlayerController: NSObject {
    static let shared = PlayerController()
    var avPlayer: AVPlayer?

    private init(avPlayer: AVPlayer? = nil) {
        self.avPlayer = avPlayer
    }

    func playAsset(_ asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer?.play()
    }

    func togglePlayPause() {
        guard let avPlayer = avPlayer else { return }
        if avPlayer.playing {
            avPlayer.pause()
        } else {
            avPlayer.play()
        }
    }
}
