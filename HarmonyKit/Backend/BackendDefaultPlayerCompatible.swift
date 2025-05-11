//
//  BackendDefaultPlayerCompatible.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/5/25.
//

import AVFoundation

public protocol BackendDefaultPlayerCompatible {
    var typeDescription: BackendDescription { get }
    
    func assetForSong(_ song: Song) -> AVAsset?
}
