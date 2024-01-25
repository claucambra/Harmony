//
//  Player.swift
//  Harmony
//
//  Created by Claudio Cambra on 25/1/24.
//

import AVFoundation
import Foundation
import HarmonyKit

class PlayerController: NSObject, ObservableObject  {
    static let shared = PlayerController()
    @Published var avPlayer: AVPlayer? {
        willSet { avPlayer?.removeObserver(self, forKeyPath: "timeControlStatus") }
        didSet {
            avPlayer?.addObserver(
                self,
                forKeyPath: "timeControlStatus",
                options: [.old, .new],
                context: &playerContext
            )
        }
    }
    @Published var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    @Published var currentSong: Song? {
        didSet {
            guard let currentSong = currentSong else {
                avPlayer = nil
                return
            }
            avPlayer = AVPlayer(playerItem: AVPlayerItem(asset: currentSong.asset))
        }
    }
    private var playerContext = 0

    private init(avPlayer: AVPlayer? = nil) {
        self.avPlayer = avPlayer
        super.init()
    }

    func playAsset(_ asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer?.play()
    }

    func togglePlayPause() {
        guard let avPlayer = avPlayer else { return }
        if timeControlStatus != .paused {
            avPlayer.pause()
        } else {
            avPlayer.play()
        }
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard context == &playerContext else { // give super to handle own cases
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        timeControlStatus = avPlayer?.timeControlStatus ?? .paused
    }
}
