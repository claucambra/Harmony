//
//  FLACSeekTableMetadataBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACSeekTableMetadataBlock {
    struct SeekPoint: Hashable {
        static let size = 8 + 8 + 2
        static let placeholder: UInt64 = 0xFFFF_FFFF_FFFF_FFFF
        let sampleNumber: UInt64
        let streamOffset: UInt64
        let frameSamples: UInt32

        init(bytes: Data) {
            sampleNumber = bytes[0..<8].withUnsafeBytes { $0.load(as: UInt64.self) }
            streamOffset = bytes[8..<16].withUnsafeBytes { $0.load(as: UInt64.self) }
            frameSamples = bytes[16..<18].withUnsafeBytes { $0.load(as: UInt32.self) }
        }
    }

    let header: FLACMetadataBlockHeader
    let points: [SeekPoint]

    init(bytes: Data, header: FLACMetadataBlockHeader) {
        self.header = header

        let pointCount = Int(header.metadataBlockDataSize) / SeekPoint.size
        var pointTable: [SeekPoint] = []
        for i in 0..<pointCount {
            let pointStartByteIndex = i * SeekPoint.size
            let pointEndByteIndex = pointStartByteIndex + SeekPoint.size - 1
            let point = SeekPoint(bytes: bytes[pointStartByteIndex...pointEndByteIndex])
            pointTable.append(point)
        }
        points = pointTable
    }
}
