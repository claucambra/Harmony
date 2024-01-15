//
//  Song.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import Foundation

struct Song {
    var identifier: String
    var title: String
    var artist: String
    var artistIdentifier: String
    var album: String
    var albumIdentifier: String
    var duration: TimeInterval // Duration in seconds
    var materialised: Bool
    var localURL: URL
}
