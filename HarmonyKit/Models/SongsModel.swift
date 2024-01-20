//
//  SongsModel.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 18/1/24.
//

import AVFoundation
import Combine
import SwiftUI

@MainActor
public class SongsModel: ObservableObject {
    @Published public var songs: [Song] = []

    private var backends: [Backend] = []

    public init(withBackends inBackends: [Backend]) {
        backends = inBackends
        Task {
            await refresh()
        }
    }

    public func refresh() async {
        var allScannedSongs: [Song] = []
        for backend in backends {
            let scanSongs = await backend.scan()
            allScannedSongs.append(contentsOf: scanSongs)
        }
        songs = allScannedSongs
    }
}
