//
//  BackendDefaultPlayerCompatible.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/5/25.
//

import AVFoundation

public protocol BackendDefaultPlayerCompatible {
    func assetForSong(_ song: Song) -> AVAsset?
}
