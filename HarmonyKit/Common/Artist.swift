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
    @Relationship(inverse: \Album.parentArtists) public var albums: [Album] = []
    @Attribute(.unique) public var name: String
    public var downloaded: Bool = false

    public init?(songs: [Song]) {
        guard let artistName = songs.first?.artist else { return nil }
        name = artistName
        setSongs(songs)
    }

    private func setSongs(_ songs: [Song]) {
        self.songs = songs
        
        var albumDict: [String: Album] = [:]
        for song in songs {
            guard albumDict[song.album] == nil, let album = song.parentAlbum else { continue }
            albumDict[song.album] = album
        }
        albums = Array(albumDict.values)
    }
}
