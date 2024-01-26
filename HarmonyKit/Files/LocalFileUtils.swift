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
