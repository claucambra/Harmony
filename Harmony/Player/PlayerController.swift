//
//  Player.swift
//  Harmony
//
//  Created by Claudio Cambra on 25/1/24.
//

import AVFoundation
import Foundation
import HarmonyKit

fileprivate let AVPlayerTimeControlStatusKeyPath = "timeControlStatus"
fileprivate let hundredMsTime = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(MSEC_PER_SEC))

class PlayerController: NSObject, ObservableObject  {
    enum ScrubState { case inactive, started, finished }

    static let shared = PlayerController()
    @Published var avPlayer: AVPlayer? {
        willSet {
            avPlayer?.removeObserver(self, forKeyPath: AVPlayerTimeControlStatusKeyPath)
            currentTime = nil
            if periodicTimeObserver != nil {
                avPlayer?.removeTimeObserver(periodicTimeObserver!)
                periodicTimeObserver = nil
            }
        }
        didSet {
            guard let avPlayer = avPlayer else { return }
            avPlayer.addObserver(
                self,
                forKeyPath: "timeControlStatus",
                options: [.old, .new],
                context: &playerContext
            )
            songDuration = avPlayer.currentItem?.duration.seconds ?? 0
            periodicTimeObserver = avPlayer.addPeriodicTimeObserver(
                forInterval: hundredMsTime, queue: .main
            ) { [weak self] time in
                switch self?.scrubState {
                case .inactive:
                    self?.currentTime = time
                case .started, nil:
                    return
                case .finished:
                    // Prevent jumping of the scrubber
                    let seconds = self?.currentSeconds ?? 0
                    self?.currentTime = CMTime(seconds: seconds, preferredTimescale: 1)
                    self?.scrubState = .inactive
                }
            }
        }
    }
    @Published var currentSong: Song? {
        didSet {
            guard let currentSong = currentSong else {
                avPlayer = nil
                return
            }
            let playerItem = AVPlayerItem(asset: currentSong.asset)
            avPlayer = AVPlayer(playerItem: playerItem)
        }
    }
    @Published var scrubState: ScrubState = .inactive {
        didSet {
            switch scrubState {
            case .inactive, .started:
                return
            case .finished:
                avPlayer?.seek(to: CMTime(seconds: currentSeconds, preferredTimescale: 1))
            }
        }
    }
    @Published private(set) var currentTime: CMTime? {
        didSet { currentSeconds = currentTime?.seconds ?? 0 }
    }
    @Published private(set) var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    @Published var currentSeconds: TimeInterval = 0
    @Published var songDuration: TimeInterval = 0
    @Published var queue = PlayerQueue()
    private var playerContext = 0
    private var periodicTimeObserver: Any?

    private init(avPlayer: AVPlayer? = nil) {
        self.avPlayer = avPlayer
        super.init()
    }

    @MainActor func playSong(_ song: Song, withinSongs songs: [Song]) {
        assert(songs.contains(song))
        
        currentSong = song

        var futureSongs: [Song] = []
        if let futureSongsIdx = songs.firstIndex(of: song) {
            futureSongs = Array(songs.dropFirst(futureSongsIdx + 1))
        }
        queue.addCurrentSong(song, withFutureSongs: futureSongs)

        avPlayer?.play()
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

        guard let keyPath = keyPath else { return }
        if keyPath == AVPlayerTimeControlStatusKeyPath {
            timeControlStatus = avPlayer?.timeControlStatus ?? .paused
        }
    }
}
