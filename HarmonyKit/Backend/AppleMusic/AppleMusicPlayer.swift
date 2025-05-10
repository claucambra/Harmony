//
//  AppleMusicPlayer.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/5/25.
//

import Combine
import MusicKit
import MediaPlayer

public class AppleMusicPlayer: BackendPlayer {
    private let internalPlayer = ApplicationMusicPlayer.shared

    public var backend: AppleMusicBackend?
    public var song: Song? {
        get {
            guard let currentEntryId = internalPlayer.queue.currentEntry?.id else { return nil }
            return backend?.harmonySongFromId(currentEntryId)
        }
        set {
            guard let appleMusicSongId = newValue?.identifier,
                  let appleMusicSong = backend?.appleMusicSongSynchronous(id: appleMusicSongId)
            else {
                stop()
                return
            }
            internalPlayer.queue = .init(arrayLiteral: appleMusicSong)
        }
    }
    public var volume: Float = 100
    public var state: AVPlayer.TimeControlStatus = .paused
    public var rate: Float {
        get { internalPlayer.state.playbackRate }
        set { internalPlayer.state.playbackRate = newValue }
    }
    public var time: TimeInterval {
        get { internalPlayer.playbackTime }
        set { internalPlayer.playbackTime = newValue }
    }

    private var stateCancellable: Cancellable?
    private var playbackTimer: Timer?

    public func play() async {
        Task { @MainActor in self.state = .waitingToPlayAtSpecifiedRate }
        try? await internalPlayer.play()
    }
    
    public func pause() {
        internalPlayer.pause()
    }
    
    public func stop() {
        internalPlayer.stop()
    }

    public required init() {
        self.stateCancellable = internalPlayer
            .state
            .objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let state = self.internalPlayer.state
                self.rate = state.playbackRate

                switch state.playbackStatus {
                case .interrupted, .paused, .stopped:
                    self.state = .paused
                case .playing, .seekingForward, .seekingBackward:
                    self.state = .playing
                }
            }
        self.playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            // Ensure we are still playing before updating
            if self.internalPlayer.state.playbackStatus == .playing {
                self.objectWillChange.send()
            }
        }
    }
}
