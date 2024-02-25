//
//  LocalFileUtils.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 17/1/24.
//

import AVFoundation
import CryptoKit
import OSLog

#if os(macOS)
import AppKit
#endif

public enum LocalURLChoiceEligibility {
    case onlyFiles, onlyDirectories, filesOrDirectories
}

func calculateMD5Checksum(forFileAtLocalURL url: URL) -> String? {
    do {
        let fileData = try Data(contentsOf: url)
        let checksum = Insecure.MD5.hash(data: fileData)
        let checksumString = checksum.map { String(format: "%02hhx", $0) }.joined()
        return checksumString
    } catch {
        print("Error reading file before calculating MD5 checksum: \(error)")
        return nil
    }
}

public func backendStorageUrl(backendId: String) -> URL? {
    guard let storageUrl = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
    ).first else {
        Logger.defaultLog.error("Could not get app support dir url for backend \(backendId)")
        return nil
    }

    return storageUrl.appendingPathComponent(backendId, conformingTo: .directory)
}

func localFileURL(song: Song) -> URL? {
    guard let backendUrl = backendStorageUrl(backendId: song.backendId) else {
        Logger.defaultLog.error("Could not get application support directory url for \(song.url)")
        return nil
    }

    let songFileName = song.identifier + "." + song.url.pathExtension
    let songUrl = backendUrl.appendingPathComponent(songFileName, conformingTo: .audio)
    return songUrl
}

#if os(macOS)
public func chooseLocalURL(eligible: LocalURLChoiceEligibility, multiple: Bool = false) -> URL? {
    let dialog = NSOpenPanel()
    dialog.canChooseFiles = eligible == .onlyFiles || eligible == .filesOrDirectories
    dialog.canChooseDirectories = eligible == .onlyDirectories || eligible == .filesOrDirectories
    dialog.allowsMultipleSelection = multiple

    if (dialog.runModal() == NSApplication.ModalResponse.OK) {
        return dialog.url
    }
    return nil
}
#endif
