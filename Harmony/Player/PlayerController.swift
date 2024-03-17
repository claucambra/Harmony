//
//  Player.swift
//  Harmony
//
//  Created by Claudio Cambra on 25/1/24.
//

import AVFoundation
import AVKit
import Foundation
import HarmonyKit
import MediaPlayer
import OSLog
import SwiftData

#if os(macOS)
import AppKit
#else
import UIKit
#endif

fileprivate let AVPlayerTimeControlStatusKeyPath = "timeControlStatus"
fileprivate let hundredMsTime = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(MSEC_PER_SEC))

fileprivate let UserDefaultsVolumeKey = "player-volume"

@MainActor
class PlayerController: NSObject, ObservableObject  {
    enum ScrubState { case inactive, started, finished }

    static let shared = PlayerController()
    #if !os(macOS)
    let audioSession = AVAudioSession.sharedInstance()
    #endif
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    @Published var currentSong: Song? {
        didSet {
            guard let currentSong = currentSong else {
                Logger.player.error("Provided current song is nil")
                avPlayer = nil
                nowPlayingInfoCenter.nowPlayingInfo = nil
                return
            }

            guard let asset = BackendsModel.shared.assetForSong(currentSong) else {
                Logger.player.error("Could not acquire asset for song \(currentSong.url)")
                avPlayer = nil
                nowPlayingInfoCenter.nowPlayingInfo = nil
                return
            }

            let playerItem = AVPlayerItem(asset: asset)
            avPlayer = AVPlayer(playerItem: playerItem)
            updateNowPlayingMetadataInfo()
            Logger.player.info("Set current song: \(currentSong.title) \(currentSong.url)")
        }
    }
    @Published private var avPlayer: AVPlayer? {
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
                songDuration = currentSong?.duration ?? 0
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
    @Published var volume: Float = UserDefaults.standard.float(forKey: UserDefaultsVolumeKey) {
        didSet {
            UserDefaults.standard.set(volume, forKey: UserDefaultsVolumeKey)
            avPlayer?.volume = volume
        }
    }
    @Published var scrubState: ScrubState = .inactive {
        didSet {
            switch scrubState {
            case .inactive, .started:
                return
            case .finished:
                seek(to: currentSeconds)
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
        didSet {
            currentSeconds = currentTime?.seconds ?? 0
            updateNowPlayingPlaybackInfo()
        }
    }
    @Published private(set) var displayedCurrentTime: String = "0:00"
    @Published private(set) var displayedSongDuration: String = "0:00"
    @Published private(set) var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    @Published private(set) var queue = PlayerQueue()
    private var playerContext = 0
    private var periodicTimeObserver: Any?

    override init() {
        super.init()

        #if !os(macOS)
        do {
            try audioSession.setCategory(.playback)
        } catch let error {
            Logger.player.error("Failed to set the audio session configuration: \(error)")
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )
        #endif

        if UserDefaults.standard.value(forKey: UserDefaultsVolumeKey) == nil {
            volume = 1.0
        }

        remoteCommandCenter.playCommand.addTarget { _ in self.play() }
        remoteCommandCenter.pauseCommand.addTarget { _ in self.pause() }
        remoteCommandCenter.togglePlayPauseCommand.addTarget { _ in self.togglePlayPause() }
        remoteCommandCenter.nextTrackCommand.addTarget { _ in self.playNextSong() }
        remoteCommandCenter.previousTrackCommand.addTarget { _ in self.playPreviousSong() }
        remoteCommandCenter.changePlaybackPositionCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            return self.seek(to: event.positionTime)
        }
        remoteCommandCenter.seekForwardCommand.addTarget { event in
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            return self.seekForwards(event: event)
        }
        remoteCommandCenter.seekBackwardCommand.addTarget { event in
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            return self.seekBackwards(event: event)
        }
        // TODO: skipForward, skipBackward, changePlaybackRate
    }

    func updateNowPlayingMetadataInfo() {
        guard let currentSong = currentSong else {
            return
        }

        nowPlayingInfoCenter.nowPlayingInfo = [
            MPNowPlayingInfoPropertyAssetURL: currentSong.url,
            MPNowPlayingInfoPropertyMediaType: MPMediaType.music.rawValue,
            //TODO: MPNowPlayingInfoPropertyIsLiveStream
            MPMediaItemPropertyTitle: currentSong.title,
            MPMediaItemPropertyAlbumTitle: currentSong.album,
            MPMediaItemPropertyArtist: currentSong.artist,
            // TODO: MPMediaItemPropertyAlbumArtist
        ]

        guard let artworkData = currentSong.artwork else { return }
        #if os(macOS)
        guard let image = NSImage(data: artworkData) else { return }
        #else
        guard let image = UIImage(data: artworkData) else { return }
        #endif
        let mpArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] = mpArtwork
    }

    func updateNowPlayingPlaybackInfo() {
        guard let currentTime = currentTime,
              let avPlayer = avPlayer else {
            return
        }

        let playbackInfo: [String: Any] = [
            MPNowPlayingInfoPropertyPlaybackRate: avPlayer.rate,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime.seconds,
            MPMediaItemPropertyPlaybackDuration: songDuration
        ]
        nowPlayingInfoCenter.nowPlayingInfo?.merge(playbackInfo) { current, new in new }
    }

    #if !os(macOS)
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        // Switch over the interruption type.
        switch type {
        case .began:
            pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                play()
            }
        @unknown default:
            return
        }
    }
    #endif

    @discardableResult func play() -> MPRemoteCommandHandlerStatus {
        guard let avPlayer = avPlayer else { return playNextSong() }
        #if os(macOS)
        nowPlayingInfoCenter.playbackState = .playing
        #else
        do {
            try audioSession.setActive(true)
        } catch let error {
            Logger.player.error("Failed to activate audio session: \(error)")
        }
        #endif
        avPlayer.play()
        return .success
    }

    @discardableResult func pause() -> MPRemoteCommandHandlerStatus {
        guard let avPlayer = avPlayer else { return .noActionableNowPlayingItem }
        #if os(macOS)
        nowPlayingInfoCenter.playbackState = .paused
        #endif
        avPlayer.pause()
        return .success
    }

    func playSong(_ song: Song, withinSongs songs: [Song]) {
        currentSong = song
        queue.addCurrentSong(song, parentResults: songs)
        play()
    }

    func applyCurrentSongFromQueue() {
        guard let queueCurrentSong = queue.currentSong else {
            Logger.player.error("No current song in queue")
            return
        }
        currentSong = queueCurrentSong.song
    }

    func playSongFromQueue(instanceId: ObjectIdentifier) {
        Task {
            await queue.moveToSong(instanceId: instanceId)
            guard let queueCurrentSong = queue.currentSong else {
                Logger.player.error("No current song in queue")
                return
            }
            Task { @MainActor in
                currentSong = queueCurrentSong.song
                play()
            }
        }
    }

    @discardableResult func togglePlayPause() -> MPRemoteCommandHandlerStatus {
        if timeControlStatus != .paused {
            return pause()
        } else {
            return play()
        }
    }

    @discardableResult func playNextSong() -> MPRemoteCommandHandlerStatus {
        guard let nextSong = queue.forward() else {
            return .noActionableNowPlayingItem
        }
        currentSong = nextSong
        return play()
    }

    @discardableResult func playPreviousSong() -> MPRemoteCommandHandlerStatus {
        if let currentTime = currentTime, currentTime.seconds > backToStartThreshold {
            return seek(to: 0)
        } else if let previousSong = queue.backward() {
            currentSong = previousSong
            return play()
        } else {
            return seek(to: 0) // Returns .noActionableNowPlayingItem if no item
        }
    }

    @discardableResult func seek(to position: TimeInterval) -> MPRemoteCommandHandlerStatus {
        guard let avPlayer = avPlayer else { return .noActionableNowPlayingItem }
        let timescale = currentTime?.timescale ?? 1
        avPlayer.seek(to: CMTime(seconds: position, preferredTimescale: timescale))
        return .success
    }

    private func setRate(_ rate: Float) -> MPRemoteCommandHandlerStatus {
        guard let avPlayer = avPlayer else { return .noActionableNowPlayingItem }
        avPlayer.rate = rate
        return .success
    }

    @discardableResult func seekForwards(
        event: MPSeekCommandEvent
    ) -> MPRemoteCommandHandlerStatus {
        return setRate(event.type == .beginSeeking ? 3.0 : 1.0)
    }

    @discardableResult func seekBackwards(
        event: MPSeekCommandEvent
    ) -> MPRemoteCommandHandlerStatus {
        return setRate(event.type == .beginSeeking ? -3.0 : 1.0)
    }


    @objc func playerDidFinishPlayingItemToEnd(notification: Notification) {
        let nextResult = playNextSong()
        if nextResult == .noActionableNowPlayingItem {
            pause()
            currentSong = nil
            queue.returnToStart()
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

    #if os(macOS)
    func configureRoutePickerView(_ routePickerView: AVRoutePickerView) {
        routePickerView.player = avPlayer
    }
    #endif
}
