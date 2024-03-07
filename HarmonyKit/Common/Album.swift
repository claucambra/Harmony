//
//  Album.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 29/2/24.
//

import Foundation
import SwiftData

@Model
public final class Album {
    @Relationship(deleteRule: .cascade, inverse: \Song.parentAlbum) public var songs: [Song] = []
    @Attribute(.unique) public var title: String
    public var artist: String?
    public var genre: String?
    public var year: Int?
    @Attribute(.externalStorage) public var artwork: Data?

    public init?(songs: [Song]) {
        guard let referenceSong = songs.first else { return nil }
        title = referenceSong.album
        artist = referenceSong.artist
        genre = referenceSong.genre
        year = referenceSong.year
        artwork = referenceSong.artwork
        setSongs(songs)
    }

    private func setSongs(_ songs: [Song]) {
        self.songs = songs
    }
}
