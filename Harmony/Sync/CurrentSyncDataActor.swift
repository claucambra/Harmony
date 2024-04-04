//
//  CurrentSyncDataActor.swift
//  Harmony
//
//  Created by Claudio Cambra on 5/4/24.
//

import Foundation

actor CurrentSyncActor {
    var foundSongs: [String: String] = [:]  // song id, backend id
    var foundContainers: [String: String] = [:]  // container id, backend id
    var skippedContainers: [String: String] = [:]  // container id, backend id

    func addFound(songId: String, backendId: String) {
        foundSongs[songId] = backendId
    }

    func addFound(containerId: String, backendId: String) {
        foundContainers[containerId] = backendId
    }

    func addSkipped(containerId: String, backendId: String) {
        skippedContainers[containerId] = backendId
    }

    func removeFound(songIds: [String]) {
        songIds.forEach { foundSongs.removeValue(forKey: $0) }
    }

    func removeFound(containerIds: [String]) {
        containerIds.forEach { foundContainers.removeValue(forKey: $0) }
    }

    func removeSkipped(containerIds: [String]) {
        containerIds.forEach { skippedContainers.removeValue(forKey: $0) }
    }
}
