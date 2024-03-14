//
//  UIAlbumUtils.swift
//  Harmony
//
//  Created by Claudio Cambra on 14/3/24.
//

import Foundation
import HarmonyKit

func sortedAlbumSongs(_ album: Album) -> [Song] {
    album.songs.sorted {
        guard $0.trackNumber != 0, $1.trackNumber != 0 else { return $0.title < $1.title }
        return $0.trackNumber < $1.trackNumber
    }
}

@MainActor
func playAlbum(_ album: Album) {
    guard let firstSong = album.songs.first else { return }
    let controller = PlayerController.shared
    let sortedSongs = sortedAlbumSongs(album)
    PlayerController.shared.playSong(firstSong, withinSongs: sortedSongs)
}

@MainActor
func playNextAlbum(_ album: Album) {
    let sortedSongs = sortedAlbumSongs(album)
    for song in sortedSongs {
        PlayerController.shared.queue.insertNextSong(song)
    }
}

func fetchAlbum(_ album: Album) {
    for song in album.songs {
        let backend = BackendsModel.shared.backends[song.backendId]
        Task { await backend?.fetchSong(song) }
    }
}

func evictAlbum(_ album: Album) {
    for song in album.songs {
        let backend = BackendsModel.shared.backends[song.backendId]
        Task { await backend?.evictSong(song) }
    }
}
