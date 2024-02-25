//
//  KeychainUtils.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/2/24.
//

import Foundation
import OSLog

func savePasswordInKeychain(
    _ password: String, forBackend backendId: String, withFieldId fieldId: String
) {
    guard let bundleId = Bundle.main.bundleIdentifier else { return }
    let query: [String: AnyObject] = [
        kSecAttrService as String: bundleId as AnyObject,
        kSecAttrAccount as String: backendId + "/" + fieldId as AnyObject,
        kSecClass as String: kSecClassGenericPassword,
        kSecValueData as String: password as AnyObject
    ]

    var status = SecItemAdd(query as CFDictionary, nil )

    if status == errSecDuplicateItem {
        status = SecItemUpdate(
            query as CFDictionary,
            [kSecValueData as String: password as AnyObject] as CFDictionary
        )
    }

    guard status == errSecSuccess else {
        Logger.config.error("Error saving password for \(backendId), received status \(status)")
        return
    }

    Logger.config.debug("Saved password under \(bundleId) \(backendId + "/" + fieldId)")
}
