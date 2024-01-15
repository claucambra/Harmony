//
//  LocalBackend.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import Foundation

class LocalBackend : NSObject, Backend {
    var songs: [Song] = []
    
    func fetchSong(_ song: Song) {
        return
    }
    
    func evictSong(_ song: Song) {
        return
    }
}
