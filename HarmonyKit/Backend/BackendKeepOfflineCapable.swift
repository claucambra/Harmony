//
//  BackendKeepOfflineCapable.swift
//  Harmony
//
//  Created by Claudio Cambra on 10/5/25.
//

public protocol BackendKeepOfflineCapable {
    func fetchSong(_ song: Song) async
    func evictSong(_ song: Song) async
}
