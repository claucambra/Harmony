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
    public var parentArtists: [Artist] = []
    @Attribute(.unique) public var title: String
    public var artist: String?
    public var genre: String?
    public var year: Int?
    @Attribute(.externalStorage) public var artwork: Data?
    public var downloaded: Bool = false

    public init?(songs: [Song]) {
        guard let referenceSong = songs.first else { return nil }
        title = referenceSong.album
        artist = referenceSong.artist
        genre = referenceSong.genre
        year = referenceSong.year
        artwork = referenceSong.artwork
        self.songs = songs
        updateDownloaded()
    }

    #if DEBUG
    init(
        songs: [Song],
        parentArtists: [Artist] = [],
        title: String,
        artist: String? = nil,
        genre: String? = nil,
        year: Int? = nil,
        artwork: Data? = nil,
        downloaded: Bool = false
    ) {
        self.songs = songs
        self.parentArtists = parentArtists
        self.title = title
        self.artist = artist
        self.genre = genre
        self.year = year
        self.artwork = artwork
        self.downloaded = downloaded
    }
    #endif

    func updateDownloaded() {
        downloaded = songs.filter { $0.downloadState != DownloadState.downloaded.rawValue }.isEmpty
    }
}
