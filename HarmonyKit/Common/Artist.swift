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
    @Relationship(deleteRule: .cascade, inverse: \Song.parentArtists) public var songs: [Song] = []
    @Relationship(inverse: \Album.parentArtists) public var albums: [Album] = []
    @Attribute(.unique) public var name: String
    public var downloaded: Bool = false

    public init?(name: String, songs: [Song]) {
        self.name = name
        self.songs = songs

        var albumDict: [String: Album] = [:]
        for song in songs {
            guard albumDict[song.album] == nil, let album = song.parentAlbum else { continue }
            albumDict[song.album] = album
        }
        albums = Array(albumDict.values)
    }

    #if DEBUG
    init(songs: [Song], albums: [Album] = [], name: String, downloaded: Bool = false) {
        self.songs = songs
        self.albums = albums
        self.name = name
        self.downloaded = downloaded
    }
    #endif
}
