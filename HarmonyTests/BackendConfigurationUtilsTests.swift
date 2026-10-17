//
//  BackendConfigurationUtilsTests.swift
//  HarmonyTests
//

import Foundation
import XCTest
@testable import Harmony
@testable import HarmonyKit

final class BackendConfigurationUtilsTests: XCTestCase {
    private let descriptionId = "test-backend"
    private let passwordFieldId = "password-field"
    private var defaultsName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        defaultsName = "BackendConfigurationUtilsTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: defaultsName)
        defaults = nil
        try super.tearDownWithError()
    }

    private func storedConfig(id: String) -> BackendConfiguration {
        [
            BackendConfigurationIdFieldKey: id,
            passwordFieldId + BackendConfigurationPasswordFieldKeySuffix: passwordFieldId,
            "serverurl-field": "https://example.com",
            "musicpath-field": "/Music",
            "custom-setting": true
        ]
    }

    func testDeleteBackendKeepsSurvivingPasswordInKeychain() throws {
        let deletedConfig = storedConfig(id: "test-backend0")
        let survivingConfig = storedConfig(id: "test-backend1")
        defaults.set([deletedConfig, survivingConfig], forKey: descriptionId)
        var keychain = [
            "test-backend0/\(passwordFieldId)": "fake-password-0",
            "test-backend1/\(passwordFieldId)": "fake-password-1"
        ]
        var deletedKeys: [String] = []
        var updateCount = 0

        deleteBackendConfig(
            id: "test-backend0", withBackendDescriptionId: descriptionId, defaults: defaults,
            deletePassword: { backendId, fieldId in
                let key = backendId + "/" + fieldId
                deletedKeys.append(key)
                keychain.removeValue(forKey: key)
            },
            updateBackends: { updateCount += 1 }
        )

        let stored = try XCTUnwrap(defaults.array(forKey: descriptionId) as? [BackendConfiguration])
        XCTAssertEqual(stored.count, 1)
        XCTAssertTrue(NSDictionary(dictionary: stored[0]).isEqual(to: survivingConfig))
        XCTAssertNil(stored[0][passwordFieldId])
        XCTAssertEqual(deletedKeys, ["test-backend0/\(passwordFieldId)"])
        XCTAssertEqual(keychain, ["test-backend1/\(passwordFieldId)": "fake-password-1"])
        XCTAssertEqual(updateCount, 1)

        let hydrated = existingConfigsForBackend(
            descriptionId: descriptionId, defaults: defaults,
            getPassword: { keychain[$0 + "/" + $1] }
        )
        XCTAssertEqual(hydrated.first?[passwordFieldId] as? String, "fake-password-1")
        let afterRead = try XCTUnwrap(defaults.array(forKey: descriptionId) as? [BackendConfiguration])
        XCTAssertNil(afterRead[0][passwordFieldId])
    }

    func testDeletingMissingBackendLeavesSettingsAndKeychainUnchanged() throws {
        let config = storedConfig(id: "test-backend0")
        defaults.set([config], forKey: descriptionId)

        deleteBackendConfig(
            id: "missing", withBackendDescriptionId: descriptionId, defaults: defaults,
            deletePassword: { _, _ in XCTFail("Must not delete another backend's password") },
            updateBackends: { XCTFail("Must not refresh unchanged backends") }
        )

        let stored = try XCTUnwrap(defaults.array(forKey: descriptionId) as? [BackendConfiguration])
        XCTAssertEqual(stored.count, 1)
        XCTAssertTrue(NSDictionary(dictionary: stored[0]).isEqual(to: config))
    }
}
