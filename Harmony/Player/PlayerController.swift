//
//  Player.swift
//  Harmony
//
//  Created by Claudio Cambra on 25/1/24.
//

import AVFoundation
import Foundation
import HarmonyKit
import OSLog

fileprivate let AVPlayerTimeControlStatusKeyPath = "timeControlStatus"
fileprivate let hundredMsTime = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(MSEC_PER_SEC))

class PlayerController: NSObject, ObservableObject  {
    enum ScrubState { case inactive, started, finished }

    static let shared = PlayerController()
    @Published var avPlayer: AVPlayer? {
        willSet {
            avPlayer?.removeObserver(self, forKeyPath: AVPlayerTimeControlStatusKeyPath)
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: avPlayer?.currentItem
            )
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
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlayingItemToEnd),
                name: .AVPlayerItemDidPlayToEndTime,
                object: avPlayer.currentItem
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
            Logger.player.info("Set current song: \(currentSong.title)")
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
    @Published var songDuration: TimeInterval = 0 {
        didSet {
            let durationDuration = Duration.seconds(songDuration)
            displayedSongDuration = durationDuration.formatted(.time(pattern: .minuteSecond))
        }
    }
    @Published var currentSeconds: TimeInterval = 0 { // Manipulable by scrubber
        didSet {
            let currentDuration = Duration.seconds(currentSeconds)
            displayedCurrentTime = currentDuration.formatted(.time(pattern: .minuteSecond))
        }
    }
    @Published private(set) var currentTime: CMTime? { // Always indicates actual current time
        didSet { currentSeconds = currentTime?.seconds ?? 0 }
    }
    @Published private(set) var displayedCurrentTime: String = "0:00"
    @Published private(set) var displayedSongDuration: String = "0:00"
    @Published private(set) var timeControlStatus: AVPlayer.TimeControlStatus = .paused
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

    func playNextSong() {
        guard let nextSong = queue.forward() else { return }
        currentSong = nextSong
        avPlayer?.play()
    }

    func playPreviousSong() {
        guard let previousSong = queue.backward() else { return }
        currentSong = previousSong
        avPlayer?.play()
    }

    @objc func playerDidFinishPlayingItemToEnd(notification: Notification) {
        playNextSong()
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