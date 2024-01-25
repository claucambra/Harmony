//
//  LocalFileUtils.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 17/1/24.
//

import AVFoundation
import CryptoKit

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
        print("Error reading file or calculating MD5 checksum: \(error)")
        return nil
    }
}

func songsFromLocalUrls(_ urls:[URL]) async -> [Song] {
    var songs: [Song] = []
    for url in urls {
        let asset = AVAsset(url: url)
        guard let csum = calculateMD5Checksum(forFileAtLocalURL: url) else { continue }
        guard let song = await Song(fromAsset: asset, withIdentifier: csum) else { continue }
        songs.append(song)
    }
    return songs
}

#if os(macOS)
public func chooseLocalURL(eligible: LocalURLChoiceEligibility, multiple: Bool = false) -> URL? {
    let dialog = NSOpenPanel()
    dialog.canChooseFiles = eligible == .onlyFiles || eligible == .filesOrDirectories
    dialog.canChooseDirectories = eligible == .onlyDirectories || eligible == .filesOrDirectories
    dialog.allowsMultipleSelection = multiple

    if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
        return dialog.url
    }
    return nil
}
#endif
