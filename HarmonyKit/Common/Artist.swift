//
//  Artist.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 12/3/24.
//

import Foundation
import SwiftData

@Model
public final class Artist {
    @Relationship(deleteRule: .cascade, inverse: \Song.parentArtist) public var songs: [Song] = []
    @Attribute(.unique) public var name: String
    public var downloaded: Bool = false

    public init?(songs: [Song]) {
        guard let artistName = songs.first?.artist else { return nil }
        name = artistName
        setSongs(songs)
    }

    private func setSongs(_ songs: [Song]) {
        self.songs = songs
    }
}
