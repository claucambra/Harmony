//
//  Backend.swift
//  Harmony
//
//  Created by Claudio Cambra on 11/1/24.
//

import Foundation

public protocol Backend {
    static var description: BackendDescription { get }

    func scan() async -> [Song]
    func fetchSong(_ song: Song) async
    func evictSong(_ song: Song) async

    init(config: BackendConfiguration)
}
