//
//  Backend.swift
//  Harmony
//
//  Created by Claudio Cambra on 11/1/24.
//

import AVFoundation
import Foundation

public let BackendNewScanRequiredNotification = Notification.Name("BackendNewScanRequired")

public enum ScanError: Error {
    case generalError(String)
    case remoteReadError(String)
}

public protocol Backend: Identifiable, Hashable, ObservableObject {
    var typeDescription: BackendDescription { get }
    var backendId: String { get }
    var presentation: BackendPresentable { get }
    var configValues: BackendConfiguration { get }

    func scan(
        containerScanApprover: @Sendable @escaping (String, String) async -> Bool,  // ID, VersionID
        songScanApprover: @Sendable @escaping (String, String) async -> Bool,  // ID, VersionID
        finalisedSongHandler: @Sendable @escaping (Song) async -> Void,
        finalisedContainerHandler: @Sendable @escaping (Container, Container?) async -> Void
    ) async throws  // Container, ParentContainer | final container handler must run after all songs
    func cancelScan()

    func assetForSong(_ song: Song) -> AVAsset?
    func fetchSong(_ song: Song) async
    func evictSong(_ song: Song) async

    init(config: BackendConfiguration)
}
