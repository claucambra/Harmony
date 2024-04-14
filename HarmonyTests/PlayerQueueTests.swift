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
    let shortSongResults = [
        Song(identifier: "1"),
        Song(identifier: "2"),
        Song(identifier: "3"),
    ]
    let longSongResults = [
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
        Song(identifier: "11"),
        Song(identifier: "12"),
        Song(identifier: "13"),
        Song(identifier: "14"),
        Song(identifier: "15"),
        Song(identifier: "16"),
        Song(identifier: "17"),
        Song(identifier: "18"),
        Song(identifier: "19"),
        Song(identifier: "20"),
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

    @MainActor static func testAddCurrentSong(results: [Song], playerQueue: PlayerQueue) {
        let futureCount = min(results.count, PlayerQueue.defaultPageSize + 1)
        let futureSongIds = results[1..<futureCount].map { $0.identifier }
        playerQueue.addCurrentSong(results.first!, parentResults: results)
        XCTAssertEqual(playerQueue.currentSong?.song, results.first!)
        XCTAssertEqual(playerQueue.results, results)
        XCTAssertEqual(playerQueue.futureSongs.map { $0.identifier }, futureSongIds)
    }

    func testAddCurrentSong_Basic() async {
        await Self.testAddCurrentSong(results: basicSongResults, playerQueue: playerQueue)
    }

    func testAddCurrentSong_Short() async {
        await Self.testAddCurrentSong(results: shortSongResults, playerQueue: playerQueue)
    }

    func testAddCurrentSong_Long() async {
        await Self.testAddCurrentSong(results: longSongResults, playerQueue: playerQueue)
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

    @MainActor static func testRepeatQueue_ContinuesToPlayPastEnd(
        results: [Song], playerQueue: PlayerQueue
    ) {
        let song = results.first!
        playerQueue.addCurrentSong(song, parentResults: results)
        playerQueue.repeatState = .queue
        XCTAssertEqual(playerQueue.currentSong?.song.identifier, song.identifier)

        for _ in 0..<results.count * 12 {
            _ = playerQueue.forward()
        }

        XCTAssertEqual(playerQueue.currentSong?.song.identifier, song.identifier)
    }

    @MainActor func testRepeatQueue_BasicQueue_ContinuesToPlayPastEnd() {
        Self.testRepeatQueue_ContinuesToPlayPastEnd(
            results: basicSongResults, playerQueue: playerQueue
        )
    }

    @MainActor func testRepeatQueue_ShortQueue_ContinuesToPlayPastEnd() {
        Self.testRepeatQueue_ContinuesToPlayPastEnd(
            results: shortSongResults, playerQueue: playerQueue
        )
    }

    @MainActor func testRepeatQueue_LongQueue_ContinuesToPlayPastEnd() {
        Self.testRepeatQueue_ContinuesToPlayPastEnd(
            results: longSongResults, playerQueue: playerQueue
        )
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

    @MainActor func testForward_WithEmptyQueue_ReturnsNil() {
        XCTAssertNil(playerQueue.forward())
    }

    @MainActor func testBackward_WithNoPastSongs_ReturnsNil() {
        XCTAssertNil(playerQueue.backward())
    }

    @MainActor static func testForward_NoRepeating(results: [Song], playerQueue: PlayerQueue) {
        let song = results.first!
        playerQueue.addCurrentSong(song, parentResults: results)
        XCTAssertEqual(playerQueue.currentSong?.song.identifier, song.identifier)

        for _ in 1..<results.count { // Skip the first song as that is set to the current song
            XCTAssertNotNil(playerQueue.forward())
        }

        XCTAssertNil(playerQueue.forward())
    }

    func testForward_NoRepeating_Basic() async {
        await Self.testForward_NoRepeating(results: basicSongResults, playerQueue: playerQueue)
    }

    func testForward_NoRepeating_Short() async {
        await Self.testForward_NoRepeating(results: shortSongResults, playerQueue: playerQueue)
    }

    func testForward_NoRepeating_Long() async {
        await Self.testForward_NoRepeating(results: longSongResults, playerQueue: playerQueue)
    }

    @MainActor func testForward_WithPlayNextSongs_MovesSongToCurrent() {
        basicSongResults.forEach { playerQueue.insertNextSong($0) }
        basicSongResults.forEach {
            XCTAssertEqual(playerQueue.forward()?.identifier, $0.identifier)
            XCTAssertEqual(playerQueue.currentSong?.song.identifier, $0.identifier)
        }
    }
}
