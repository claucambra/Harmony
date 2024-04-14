//
//  PlayerQueueTests.swift
//  HarmonyTests
//
//  Created by Claudio Cambra on 14/4/24.
//

import XCTest
@testable import HarmonyKit
@testable import Harmony

final class PlayerQueueTests: XCTestCase {

    let defaultsName = "TestDefaults"
    var playerQueue: PlayerQueue!
    var mockUserDefaults: UserDefaults!

    @MainActor override func setUpWithError() throws {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: defaultsName)
        mockUserDefaults = UserDefaults(suiteName: defaultsName)!
        playerQueue = PlayerQueue(userDefaults: mockUserDefaults)
    }

    override func tearDownWithError() throws {
        mockUserDefaults.removePersistentDomain(forName: defaultsName)
        super.tearDown()
    }
}
