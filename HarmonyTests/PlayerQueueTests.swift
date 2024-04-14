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

    @MainActor func testShuffleEnabled_TogglesAndPersists() {
        XCTAssertFalse(playerQueue.shuffleEnabled) // Test default

        playerQueue.shuffleEnabled = true

        XCTAssertTrue(playerQueue.shuffleEnabled)
        XCTAssertTrue(mockUserDefaults.bool(forKey: UserDefaultsShuffleKey))

        // Check that on init the state is restored
        let newQueue = PlayerQueue(userDefaults: mockUserDefaults)
        XCTAssertTrue(newQueue.shuffleEnabled)

        playerQueue.shuffleEnabled = false

        XCTAssertFalse(playerQueue.shuffleEnabled)
        XCTAssertFalse(mockUserDefaults.bool(forKey: UserDefaultsShuffleKey))
    }

    @MainActor func testRepeatState_TogglesAndPersists() {
        XCTAssertEqual(playerQueue.repeatState, .disabled)

        playerQueue.repeatState = .queue
        XCTAssertEqual(playerQueue.repeatState, .queue)
        XCTAssertEqual(
            mockUserDefaults.integer(forKey: UserDefaultsRepeatKey),
            PlayerQueue.RepeatState.queue.rawValue
        )

        // Check that on init the state is restored
        let newQueue = PlayerQueue(userDefaults: mockUserDefaults)
        XCTAssertEqual(newQueue.repeatState, .queue)

        playerQueue.repeatState = .currentSong
        XCTAssertEqual(playerQueue.repeatState, .currentSong)
        XCTAssertEqual(
            mockUserDefaults.integer(forKey: UserDefaultsRepeatKey),
            PlayerQueue.RepeatState.currentSong.rawValue
        )

        playerQueue.repeatState = .disabled
        XCTAssertEqual(playerQueue.repeatState, .disabled)
        XCTAssertEqual(
            mockUserDefaults.integer(forKey: UserDefaultsRepeatKey),
            PlayerQueue.RepeatState.disabled.rawValue
        )
    }

    @MainActor func testRepeatStateCycle() {
        XCTAssertEqual(playerQueue.repeatState, .disabled)

        playerQueue.cycleRepeatState()
        XCTAssertEqual(playerQueue.repeatState, .queue)
        playerQueue.cycleRepeatState()
        XCTAssertEqual(playerQueue.repeatState, .currentSong)
        playerQueue.cycleRepeatState()
        XCTAssertEqual(playerQueue.repeatState, .disabled)
    }
}
