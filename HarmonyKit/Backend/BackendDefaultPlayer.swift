//
//  BackendDefaultPlayer.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/5/25.
//

import AVFoundation
import MediaPlayer

fileprivate let AVPlayerTimeControlStatusKeyPath = "timeControlStatus"
fileprivate let hundredMsTime = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(MSEC_PER_SEC))

public class BackendDefaultPlayer: NSObject, BackendPlayer {
    private let internalPlayer = AVPlayer()

    public var backend: (any BackendDefaultPlayerCompatible)?
    private(set)public var state: AVPlayer.TimeControlStatus = .paused
    public var song: Song? {
        didSet {
            guard let song, let asset = backend?.assetForSong(song) else {
                internalPlayer.replaceCurrentItem(with: nil)
                return
            }
            internalPlayer.replaceCurrentItem(with: AVPlayerItem(asset: asset))
        }
    }
    public var volume: Float {
        get { internalPlayer.volume }
        set { internalPlayer.volume = newValue }
    }
    public var rate: Float {
        get { internalPlayer.rate }
        set { internalPlayer.rate = newValue }
    }
    public var time: TimeInterval {
        get { internalPlayer.currentTime().seconds }
        set { internalPlayer.seek(to: CMTime(seconds:newValue, preferredTimescale: 1)) }
    }

    private var playerContext = 0
    private var periodicTimeObserver: Any?

    public func play() async {
        internalPlayer.play()
    }
    
    public func pause() {
        internalPlayer.pause()
    }
    
    public func stop() {
        internalPlayer.pause()
        self.time = 0
    }
    
    public override init() {
        super.init()

        internalPlayer.addObserver(
            self,
            forKeyPath: "timeControlStatus",
            options: [.old, .new],
            context: &playerContext
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlayingItemToEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: internalPlayer.currentItem
        )

        periodicTimeObserver = internalPlayer.addPeriodicTimeObserver(
            forInterval: hundredMsTime, queue: .main
        ) { [weak self] time in
            self?.objectWillChange.send()
        }
    }

    @objc func playerDidFinishPlayingItemToEnd(notification: Notification) {
        objectWillChange.send()
    }

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard context == &playerContext else { // give super to handle own cases
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        guard let keyPath, keyPath == AVPlayerTimeControlStatusKeyPath else {
            return
        }
        self.state = internalPlayer.timeControlStatus
    }
}
