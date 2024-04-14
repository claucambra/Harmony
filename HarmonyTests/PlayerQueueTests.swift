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
    let basicSongResults = [
        Song(identifier: "1"),
        Song(identifier: "2"),
        Song(identifier: "3"),
        Song(identifier: "4"),
        Song(identifier: "5"),
        Song(identifier: "6"),
        Song(identifier: "7"),
        Song(identifier: "8"),
        Song(identifier: "9"),
        Song(identifier: "10"),
    ]

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

    @MainActor func testAddCurrentSong() {
        let futureSongIds = basicSongResults[1..<basicSongResults.count].map { $0.identifier }
        playerQueue.addCurrentSong(basicSongResults.first!, parentResults: basicSongResults)
        XCTAssertEqual(playerQueue.currentSong?.song, basicSongResults.first!)
        XCTAssertEqual(playerQueue.results, basicSongResults)
        XCTAssertEqual(playerQueue.futureSongs.map { $0.identifier }, futureSongIds)
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

    @MainActor func testShuffleChanges_ReloadsFutureSongs() {
        XCTAssertFalse(playerQueue.shuffleEnabled)

        let futureSongIds = basicSongResults[1..<basicSongResults.count].map { $0.identifier }
        playerQueue.addCurrentSong(basicSongResults.first!, parentResults: basicSongResults)
        XCTAssertEqual(playerQueue.results, basicSongResults)
        XCTAssertEqual(playerQueue.futureSongs.map { $0.identifier }, futureSongIds)

        playerQueue.shuffleEnabled = true
        // Check if future songs are shuffled
        XCTAssertEqual(playerQueue.futureSongs.count, futureSongIds.count)
        XCTAssertNotEqual(playerQueue.futureSongs.map { $0.identifier }, futureSongIds)
        for songId in futureSongIds {
            XCTAssertTrue(playerQueue.futureSongs.contains { $0.identifier == songId })
        }

        playerQueue.shuffleEnabled = false
        XCTAssertEqual(playerQueue.results, basicSongResults)
        XCTAssertEqual(playerQueue.futureSongs.map { $0.identifier }, futureSongIds)
    }

    @MainActor func testRepeatCurrentSong_RepeatsTheSameSong() async {
        let song = basicSongResults.first!
        playerQueue.addCurrentSong(song, parentResults: basicSongResults)
        XCTAssertEqual(playerQueue.currentSong?.song, song)

        playerQueue.repeatState = .currentSong
        // No matter how many forwards we make, should provide same song
        for _ in 0...PlayerQueue.defaultPageSize * 3 {
            XCTAssertEqual(playerQueue.forward()?.identifier, song.identifier)
        }
    }
}
