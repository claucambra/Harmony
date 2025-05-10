//
//  Player.swift
//  Harmony
//
//  Created by Claudio Cambra on 25/1/24.
//

import AVFoundation
import Combine
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
            guard let currentSong else {
                Logger.player.error("Provided current song is nil")
                player = nil
                nowPlayingInfoCenter.nowPlayingInfo = nil
                return
            }

            songDuration = currentSong.duration

            guard let player = BackendsModel.shared.playerForSong(currentSong) else {
                Logger.player.error("Could not acquire player for song \(currentSong.url)")
                player = nil
                nowPlayingInfoCenter.nowPlayingInfo = nil
                return
            }

            self.player = player
            player.song = currentSong
            updateNowPlayingMetadataInfo()
            Logger.player.info("Set current song: \(currentSong.title) \(currentSong.url)")
        }
    }
    @Published private var playerCancellable: Cancellable?
    @Published private var player: (any BackendPlayer)? {
        didSet {
            guard let player else { return }
            player.volume = volume
            playerCancellable = (player as! AppleMusicPlayer)
                .objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self, let player = self.player else { return }
                    // Only update the states in PlayerController that we depend on the player for.
                    // States that the player is a slave to (rate, volume, song, etc) should be kept
                    // out.
                    self.timeControlStatus = player.state
                    if self.scrubState == .inactive {
                        self.currentTime = CMTime(value: CMTimeValue(player.time), timescale: 1)
                    }
                    self.objectWillChange.send()
                }
        }
    }
    @Published var volume: Float = UserDefaults.standard.float(forKey: UserDefaultsVolumeKey) {
        didSet {
            UserDefaults.standard.set(volume, forKey: UserDefaultsVolumeKey)
            player?.volume = volume
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
        guard let currentSong else { return }

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
        guard let currentTime, let player else { return }
        let playbackInfo: [String: Any] = [
            MPNowPlayingInfoPropertyPlaybackRate: player.rate,
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
        guard let player else { return playNextSong() }
        #if os(macOS)
        nowPlayingInfoCenter.playbackState = .playing
        #else
        do {
            try audioSession.setActive(true)
        } catch let error {
            Logger.player.error("Failed to activate audio session: \(error)")
        }
        #endif
        Task { await player.play() }
        return .success
    }

    @discardableResult func pause() -> MPRemoteCommandHandlerStatus {
        guard let player else { return .noActionableNowPlayingItem }
        #if os(macOS)
        nowPlayingInfoCenter.playbackState = .paused
        #endif
        player.pause()
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

    func playSongFromPlayNext(instanceId: ObjectIdentifier) {
        queue.moveToPlayNextSong(instanceId: instanceId)
        applyCurrentSongFromQueue()
        play()
    }

    func playSongFromFutureSongs(instanceId: ObjectIdentifier) {
        queue.moveToFutureSong(instanceId: instanceId)
        applyCurrentSongFromQueue()
        play()
    }

    func playSongFromPastSongs(instanceId: ObjectIdentifier) {
        queue.moveToPastSong(instanceId: instanceId)
        applyCurrentSongFromQueue()
        play()
    }

    func playSongFromQueues(instanceId: ObjectIdentifier) {
        if queue.pastSongs.contains(where: { $0.id == instanceId }) {
            playSongFromPastSongs(instanceId: instanceId)
        } else if queue.playNextSongs.contains(where: { $0.id == instanceId }) {
            playSongFromPlayNext(instanceId: instanceId)
        } else if queue.futureSongs.contains(where: { $0.id == instanceId }) {
            playSongFromFutureSongs(instanceId: instanceId)
        } else {
            Logger.player.error("Song not found in any queue")
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
        guard let player else { return .noActionableNowPlayingItem }
        player.time = position
        return .success
    }

    private func setRate(_ rate: Float) -> MPRemoteCommandHandlerStatus {
        guard let player else { return .noActionableNowPlayingItem }
        player.rate = rate
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
}
