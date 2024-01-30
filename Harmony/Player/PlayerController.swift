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
import RealmSwift

fileprivate let AVPlayerTimeControlStatusKeyPath = "timeControlStatus"
fileprivate let hundredMsTime = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(MSEC_PER_SEC))

@MainActor
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
            avPlayer.volume = volume
            songDuration = avPlayer.currentItem?.duration.seconds ?? 0
            if songDuration.isNaN {
                Logger.player.warning("AVPlayer current item duration seconds isNaN.")
                Logger.player.warning("Trying to use controller's current song's duration secs.")
                songDuration = currentSong?.duration.seconds ?? 0
            }
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
                    let timeScale = self?.currentTime?.timescale ?? 1
                    self?.currentTime = CMTime(seconds: seconds, preferredTimescale: timeScale)
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
    @Published var volume: Float = 1.0 {
        didSet { avPlayer?.volume = volume }
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
            guard !songDuration.isNaN else {
                Logger.player.error("Song duration isNaN. Cannot set displayed song duration")
                return
            }
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
    @Published var backToStartThreshold: TimeInterval = 3.0
    @Published private(set) var currentTime: CMTime? { // Always indicates actual current time
        didSet { currentSeconds = currentTime?.seconds ?? 0 }
    }
    @Published private(set) var displayedCurrentTime: String = "0:00"
    @Published private(set) var displayedSongDuration: String = "0:00"
    @Published private(set) var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    @Published private(set) var queue = PlayerQueue()
    private var playerContext = 0
    private var periodicTimeObserver: Any?

    private init(avPlayer: AVPlayer? = nil) {
        self.avPlayer = avPlayer
        super.init()
    }

    @MainActor func playSong(_ dbSong: DatabaseSong, withinSongs songs: Results<DatabaseSong>) {
        let id = dbSong.identifier
        guard let song = dbSong.toSong() else {
            Logger.player.error("Could not convert dbsong with id: \(id)")
            return
        }

        currentSong = song
        queue.addCurrentSong(song, dbSong: dbSong, parentResults: songs)
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
        if let currentTime = currentTime, currentTime.seconds > backToStartThreshold {
            avPlayer?.seek(to: CMTime(seconds: 0, preferredTimescale: currentTime.timescale))
            return
        }

        guard let previousSong = queue.backward() else {
            if let currentTime = currentTime {
                avPlayer?.seek(to: CMTime(seconds: 0, preferredTimescale: currentTime.timescale))
            }
            return
        }

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
