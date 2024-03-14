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
