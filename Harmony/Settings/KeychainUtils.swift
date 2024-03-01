//
//  KeychainUtils.swift
//  Harmony
//
//  Created by Claudio Cambra on 26/2/24.
//

import Foundation
import OSLog

func getPasswordInKeychain(forBackend backendId: String, fieldId: String) -> String? {
    guard let bundleId = Bundle.main.bundleIdentifier else { return nil }
    let query: [String: AnyObject] = [
        kSecAttrService as String: bundleId as AnyObject,
        kSecAttrAccount as String: backendId + "/" + fieldId as AnyObject,
        kSecClass as String: kSecClassGenericPassword,
        kSecMatchLimit as String: kSecMatchLimitOne,
        kSecReturnData as String: kCFBooleanTrue
    ]
    var itemCopy: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)
    guard status != errSecItemNotFound else {
        Logger.config.error("No password found for \(backendId + "/" + fieldId)")
        return nil
    }
    guard status == errSecSuccess else {
        let string = SecCopyErrorMessageString(status, nil)
        Logger.config.error("Failed to get password for \(backendId + "/" + fieldId): \(string)")
        return nil
    }
    guard let password = itemCopy as? Data else {
        return nil
    }
    return String(data: password, encoding: .utf8)
}

func savePasswordInKeychain(
    _ password: String, forBackend backendId: String, withFieldId fieldId: String
) {
    guard let bundleId = Bundle.main.bundleIdentifier else { return }
    let query: [String: AnyObject] = [
        kSecAttrService as String: bundleId as AnyObject,
        kSecAttrAccount as String: backendId + "/" + fieldId as AnyObject,
        kSecClass as String: kSecClassGenericPassword,
        kSecValueData as String: password.data(using: .utf8) as AnyObject
    ]
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status != errSecDuplicateItem else {
        updatePasswordInKeychain(password, forBackend: backendId, withFieldId: fieldId)
        return
    }
    guard status == errSecSuccess else {
        let string = SecCopyErrorMessageString(status, nil)
        Logger.config.error("Error saving password for \(backendId), received status \(string)")
        return
    }
    Logger.config.debug("Saved password under \(bundleId) \(backendId + "/" + fieldId)")
}

func updatePasswordInKeychain(
    _ password: String, forBackend backendId: String, withFieldId fieldId: String
) {
    guard let bundleId = Bundle.main.bundleIdentifier else { return }
    let query: [String: AnyObject] = [
        kSecAttrService as String: bundleId as AnyObject,
        kSecAttrAccount as String: backendId + "/" + fieldId as AnyObject,
        kSecClass as String: kSecClassGenericPassword
    ]
    let attributes: [String: AnyObject] = [kSecValueData as String: password.data(using: .utf8) as AnyObject]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    guard status != errSecItemNotFound else {
        Logger.config.error("Cannot update nonexistent password under \(backendId + "/" + fieldId)")
        return
    }
    guard status == errSecSuccess else {
        let string = SecCopyErrorMessageString(status, nil)
        Logger.config.error("Error updating password under \(backendId + "/" + fieldId): \(string)")
        return
    }
    Logger.config.debug("Updated password under \(bundleId) \(backendId + "/" + fieldId)")
}

func deletePasswordInKeychain(forBackend backendId: String, withFieldId fieldId: String) {
    guard let bundleId = Bundle.main.bundleIdentifier else { return }
    let query: [String: AnyObject] = [
        kSecAttrService as String: bundleId as AnyObject,
        kSecAttrAccount as String: backendId + "/" + fieldId as AnyObject,
        kSecClass as String: kSecClassGenericPassword
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status != errSecItemNotFound else {
        Logger.config.error("Cannot delete nonexistent password under \(backendId + "/" + fieldId)")
        return
    }
    guard status == errSecSuccess else {
        let string = SecCopyErrorMessageString(status, nil)
        Logger.config.error("Error deleting password under \(backendId + "/" + fieldId): \(string)")
        return
    }
    Logger.config.debug("Deleted password under \(bundleId) \(backendId + "/" + fieldId)")
}
