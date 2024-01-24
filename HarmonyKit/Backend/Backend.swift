//
//  Backend.swift
//  Harmony
//
//  Created by Claudio Cambra on 11/1/24.
//

import Foundation

public protocol Backend: Identifiable, Hashable {
    static var description: BackendDescription { get }
    var id: String { get }
    var primaryDisplayString: String { get }
    var secondaryDisplayString: String { get }

    func scan() async -> [Song]
    func fetchSong(_ song: Song) async
    func evictSong(_ song: Song) async

    init(config: BackendConfiguration)
}
