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
    let basicSongResults = [ // Length of default page size -> future songs, so excluding first
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
    ]
    let shortSongResults = [ // Shorter than default page size
        Song(identifier: "1"),
        Song(identifier: "2"),
        Song(identifier: "3"),
    ]
    let longSongResults = [ // Longer than default page size, slightly shorter than double
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

    @MainActor func testShuffleRepeatCurrentSong_RepeatsTheSameSong() async {
        let song = basicSongResults.first!
        playerQueue.addCurrentSong(song, parentResults: basicSongResults)
        XCTAssertEqual(playerQueue.currentSong?.song, song)

        playerQueue.repeatState = .currentSong
        playerQueue.shuffleEnabled = true
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

    @MainActor static func testForward_NoRepeating_LastSong(
        results: [Song], playerQueue: PlayerQueue
    ) async {
        let song = results.last!
        playerQueue.addCurrentSong(song, parentResults: results)
        XCTAssertEqual(playerQueue.currentSong?.song.identifier, song.identifier)
        XCTAssertNil(playerQueue.forward())
    }

    func testForward_NoRepeating_LastSong_Basic() async {
        await Self.testForward_NoRepeating_LastSong(
            results: basicSongResults, playerQueue: playerQueue
        )
    }

    func testForward_NoRepeating_LastSong_Short() async {
        await Self.testForward_NoRepeating_LastSong(
            results: shortSongResults, playerQueue: playerQueue
        )
    }

    func testForward_NoRepeating_LastSong_Long() async {
        await Self.testForward_NoRepeating_LastSong(
            results: longSongResults, playerQueue: playerQueue
        )
    }

    @MainActor func testBackward_MovesSongFromPastToCurrent() {
        let song = shortSongResults.first!
        playerQueue.addCurrentSong(song, parentResults: shortSongResults)
        XCTAssertNotNil(playerQueue.forward())
        XCTAssertEqual(playerQueue.backward()?.identifier, song.identifier)
        XCTAssertEqual(playerQueue.currentSong?.song.identifier, song.identifier)
    }

    @MainActor static func testBackward_PullsFromResults(
        results: [Song], playerQueue: PlayerQueue
    ) {
        playerQueue.addCurrentSong(results.last!, parentResults: results)
        XCTAssertEqual(playerQueue.currentSong?.song.identifier, results.last?.identifier)

        for i in (0..<results.count - 1).reversed() { // Skip last song, was set to current song
            XCTAssertEqual(playerQueue.backward()?.identifier, results[i].identifier)
            XCTAssertEqual(playerQueue.currentSong?.song.identifier, results[i].identifier)
        }
    }

    func testBackward_PullsFromResults_Basic() async {
        await Self.testBackward_PullsFromResults(results: basicSongResults, playerQueue: playerQueue)
    }

    func testBackward_PullsFromResults_Short() async {
        await Self.testBackward_PullsFromResults(results: shortSongResults, playerQueue: playerQueue)
    }

    func testBackward_PullsFromResults_Long() async {
        await Self.testBackward_PullsFromResults(results: longSongResults, playerQueue: playerQueue)
    }

    @MainActor func testInsertNextSong_AddsSongCorrectly() {
        basicSongResults.forEach { playerQueue.insertNextSong($0) }
        XCTAssertEqual(
            playerQueue.playNextSongs.map { $0.identifier },
            basicSongResults.map { $0.identifier }
        )
    }

    @MainActor func testForward_WithPlayNextSongs_MovesSongToCurrent() {
        basicSongResults.forEach { playerQueue.insertNextSong($0) }
        basicSongResults.forEach {
            XCTAssertEqual(playerQueue.forward()?.identifier, $0.identifier)
            XCTAssertEqual(playerQueue.currentSong?.song.identifier, $0.identifier)
        }
    }

    @MainActor func testInsertNextSong_MovesSongImmediatelyAfterCurrent() {
        let firstSong = basicSongResults.first!
        let secondSong = longSongResults.last!
        let thirdSong = basicSongResults[1]
        playerQueue.addCurrentSong(firstSong, parentResults: basicSongResults)
        playerQueue.insertNextSong(secondSong)

        XCTAssertEqual(playerQueue.currentSong?.song, firstSong)
        XCTAssertEqual(playerQueue.forward(), secondSong)
        XCTAssertEqual(playerQueue.currentSong?.song, secondSong)
        XCTAssertEqual(playerQueue.forward(), thirdSong)
        XCTAssertEqual(playerQueue.currentSong?.song, thirdSong)
    }

    @MainActor func testClearPast() {
        playerQueue.addCurrentSong(longSongResults.first!, parentResults: longSongResults)
        longSongResults.forEach { playerQueue.insertNextSong($0) }
        XCTAssertNotNil(playerQueue.forward())
        playerQueue.clearPastSongs()

        XCTAssertNotNil(playerQueue.currentSong)
        XCTAssertTrue(playerQueue.pastSongs.isEmpty)
        XCTAssertFalse(playerQueue.playNextSongs.isEmpty)
        XCTAssertFalse(playerQueue.futureSongs.isEmpty)
    }

    @MainActor func testClearSongsAfterCurrent() {
        playerQueue.addCurrentSong(longSongResults.first!, parentResults: longSongResults)
        longSongResults.forEach { playerQueue.insertNextSong($0) }
        XCTAssertNotNil(playerQueue.forward())
        playerQueue.clearSongsAfterCurrent()

        XCTAssertNotNil(playerQueue.currentSong)
        XCTAssertFalse(playerQueue.pastSongs.isEmpty)
        XCTAssertTrue(playerQueue.playNextSongs.isEmpty)
        XCTAssertTrue(playerQueue.futureSongs.isEmpty)
    }

    @MainActor func testClear() {
        playerQueue.addCurrentSong(longSongResults.first!, parentResults: longSongResults)
        longSongResults.forEach { playerQueue.insertNextSong($0) }
        XCTAssertNotNil(playerQueue.forward())
        playerQueue.clear()

        XCTAssertTrue(playerQueue.playNextSongs.isEmpty)
        XCTAssertTrue(playerQueue.pastSongs.isEmpty)
        XCTAssertTrue(playerQueue.futureSongs.isEmpty)
        XCTAssertNotNil(playerQueue.currentSong)
    }

    @MainActor func testReset() {
        playerQueue.addCurrentSong(longSongResults.first!, parentResults: longSongResults)
        longSongResults.forEach { playerQueue.insertNextSong($0) }
        XCTAssertNotNil(playerQueue.forward())
        playerQueue.reset()

        XCTAssertTrue(playerQueue.playNextSongs.isEmpty)
        XCTAssertTrue(playerQueue.pastSongs.isEmpty)
        XCTAssertTrue(playerQueue.futureSongs.isEmpty)
        XCTAssertNil(playerQueue.currentSong)
    }

    @MainActor func testLoadNextPageIfNeeded_IsNeeded() {
        playerQueue.addCurrentSong(longSongResults.first!, parentResults: longSongResults)
        XCTAssertNotEqual(longSongResults.last, playerQueue.futureSongs.last?.song)
        playerQueue.loadNextPageIfNeeded(song: playerQueue.futureSongs.last!)
        XCTAssertEqual(longSongResults.last, playerQueue.futureSongs.last?.song)
    }

    @MainActor func testLoadNextPageIfNeeded_IsNotNeeded() {
        playerQueue.addCurrentSong(longSongResults.first!, parentResults: longSongResults)
        XCTAssertNotEqual(longSongResults.last, playerQueue.futureSongs.last?.song)
        playerQueue.loadNextPageIfNeeded(song: playerQueue.currentSong!)
        XCTAssertNotEqual(longSongResults.last, playerQueue.futureSongs.last?.song)
        playerQueue.loadNextPageIfNeeded(song: playerQueue.futureSongs.first!)
        XCTAssertNotEqual(longSongResults.last, playerQueue.futureSongs.last?.song)
    }

    @MainActor func testMoveToSong_FindsAndSetsSongAsCurrent() async {
        var insertedBasicSongResultsCount = 0
        playerQueue.addCurrentSong(basicSongResults.first!, parentResults: basicSongResults)
        insertedBasicSongResultsCount += basicSongResults.count

        playerQueue.moveToFutureSong(instanceId: playerQueue.futureSongs.first!.id)
        XCTAssertEqual(playerQueue.currentSong?.song, basicSongResults[1])
        XCTAssertEqual(playerQueue.pastSongs.first?.song, basicSongResults.first)

        // Test moving to play next. Should move to play next before future songs, as expected, with
        // play next moved into past songs. When moving into the future songs, this should also
        // behave as expected
        basicSongResults.forEach { playerQueue.insertNextSong($0) }
        insertedBasicSongResultsCount += basicSongResults.count
        playerQueue.moveToPlayNextSong(instanceId: playerQueue.playNextSongs.last!.id)
        XCTAssertEqual(playerQueue.currentSong?.song, basicSongResults.last)
        XCTAssertEqual( // Second to last song, because the last song was set to the current song
            playerQueue.pastSongs.last?.song, basicSongResults[basicSongResults.count - 2]
        )
        XCTAssertTrue(playerQueue.playNextSongs.isEmpty)

        let pastSongIndex = 2
        let pastSongTarget = playerQueue.pastSongs[pastSongIndex]
        playerQueue.moveToPastSong(instanceId: pastSongTarget.id)
        XCTAssertEqual(playerQueue.currentSong?.song, pastSongTarget.song)
        XCTAssertEqual(playerQueue.pastSongs.count, pastSongIndex)
        XCTAssertEqual(
            playerQueue.futureSongs.count, insertedBasicSongResultsCount - pastSongIndex - 1
        )
    }

    @MainActor func testReturnToStart() {
        playerQueue.addCurrentSong(basicSongResults.first!, parentResults: basicSongResults)
        XCTAssertNotNil(playerQueue.currentSong)
        while playerQueue.forward() != nil {}
        playerQueue.returnToStart()
        XCTAssertNil(playerQueue.currentSong)
        XCTAssertEqual(playerQueue.futureSongs.first?.song, basicSongResults.first)
    }
}
