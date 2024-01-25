//
//  AVPlayer+Extension.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 25/1/24.
//

import AVFoundation

extension AVPlayer {
    public var playing: Bool {
        rate != 0.0 && error == nil
    }
}
