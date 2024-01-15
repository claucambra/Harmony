//
//  Backend.swift
//  Harmony
//
//  Created by Claudio Cambra on 11/1/24.
//

import Foundation

protocol Backend {
    var songs: [Song] { get }

    func fetchSong(_ song: Song)
    func evictSong(_ song: Song)
}
