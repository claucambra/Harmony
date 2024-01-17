//
//  Backend.swift
//  Harmony
//
//  Created by Claudio Cambra on 11/1/24.
//

import Foundation

protocol Backend {
    func scan() async -> [URL]
    func fetchSong(_ song: Song) async
    func evictSong(_ song: Song) async
}
