//
//  BackendCustomPlayer.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 10/5/25.
//

import AVFoundation
import Combine

public protocol BackendPlayer:
    ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher
{
    var backendTypeId: String? { get }
    var state: AVPlayer.TimeControlStatus { get }
    var song: Song? { get set }
    var volume: Float { get set }
    var rate: Float { get set }
    var time: TimeInterval { get set }

    func play() async
    func pause()
    func stop()
}
