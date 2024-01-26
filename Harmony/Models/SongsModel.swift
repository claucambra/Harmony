//
//  SongsModel.swift
//  Harmony
//
//  Created by Claudio Cambra on 18/1/24.
//

import AVFoundation
import Combine
import HarmonyKit
import SwiftUI

@MainActor
public class SongsModel: ObservableObject {
    @Published public var songs: [Song] = []

    private var backends: [any Backend] = []

    public init(withBackends inBackends: [any Backend]) {
        backends = inBackends
        Task {
            await refresh()
        }
    }

    public func refresh() async {
        songs = await withTaskGroup(of: [Song].self, returning: [Song].self) { group in
            for backend in backends {
                group.addTask {
                    return await backend.scan()
                }
            }

            var allScannedSongs: [Song] = []
            for await result in group {
                allScannedSongs.append(contentsOf: result)
            }
            return allScannedSongs
        }
    }
}
