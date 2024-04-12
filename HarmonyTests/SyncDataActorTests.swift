//
//  SyncDataActorTests.swift
//  HarmonyTests
//
//  Created by Claudio Cambra on 12/4/24.
//

import AVFoundation
import SwiftData
import XCTest

@testable import Harmony
@testable import HarmonyKit

final class SyncDataActorTests: XCTestCase {

    var syncDataActor: SyncDataActor!
    var mockModelContainer: ModelContainer!

    override func setUpWithError() throws {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        mockModelContainer = try ModelContainer(
            for: Song.self, Album.self, Artist.self, Container.self,
            configurations: config
        )
        syncDataActor = SyncDataActor(modelContainer: mockModelContainer)
    }

    override func tearDownWithError() throws {
        syncDataActor = nil
        mockModelContainer = nil
        super.tearDown()
    }
}
