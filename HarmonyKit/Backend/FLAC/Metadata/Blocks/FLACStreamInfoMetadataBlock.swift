//
//  FLACStreamInfoMetadataBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACStreamInfoMetadataBlock {
    let header: FLACMetadataBlockHeader
    let minimumBlockSize: UInt16
    let maximumBlockSize: UInt16
    let minimumFrameSize: UInt32
    let maximumFrameSize: UInt32
    let sampleRate: UInt32
    let channels: UInt32
    let bitsPerSample: UInt32
    let totalSamples: UInt64
    let md5: String

    init(bytes: Data, header: FLACMetadataBlockHeader) {
        self.header = header

        var advancedBytes = bytes.advanced(by: 0)
        minimumBlockSize = advancedBytes[0..<2].withUnsafeBytes {
            $0.load(as: UInt16.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 2)

        maximumBlockSize = advancedBytes[0..<2].withUnsafeBytes {
            $0.load(as: UInt16.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 2)

        var usableMinimumFrameSize: UInt32 = 0
        for i in 0..<3 {
            usableMinimumFrameSize = (usableMinimumFrameSize << 8) | UInt32(advancedBytes[i])
        }
        minimumFrameSize = usableMinimumFrameSize
        advancedBytes = advancedBytes.advanced(by: 3)

        var usableMaximumFrameSize: UInt32 = 0
        for i in 0..<3 {
            usableMaximumFrameSize = (usableMaximumFrameSize << 8) | UInt32(advancedBytes[i])
        }
        maximumFrameSize = usableMaximumFrameSize
        advancedBytes = advancedBytes.advanced(by: 3)

        // This part is tricky as the values do not fall neatly into byte boundaries
        // In the next 64 bits:
        // 1. 20 bits -> sample rate
        // 2. 3 bits -> number of channels
        // 3. 5 bits -> bits per sample
        // 4. 36 bits -> total samples in stream
        let a16 = advancedBytes[0..<2].withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        let a = UInt32(a16) << 4
        sampleRate = a | (UInt32(advancedBytes[2]) & 0xF0) >> 4
        channels = (UInt32(advancedBytes[2]) & 0x0E) >> 1 + 1  // Provided value is -1, re-add 1
        bitsPerSample = (UInt32(advancedBytes[2]) & 0x01) << 4 |
                        (UInt32(advancedBytes[3]) & 0xF0) >> 4 + 1  // Provided value is -1, re-add
        totalSamples = (UInt64(advancedBytes[3]) & 0x0F) << 32 |
                        UInt64(advancedBytes[4..<8].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        })
        advancedBytes = advancedBytes.advanced(by: 8)

        md5 = advancedBytes[0..<16].compactMap({ String(format: "%02x", $0) }).joined()
    }
}
