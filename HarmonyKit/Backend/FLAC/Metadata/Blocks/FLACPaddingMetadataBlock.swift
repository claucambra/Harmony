//
//  FLACPaddingMetadataBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACPaddingMetadataBlock {
    public let header: FLACMetadataBlockHeader
    public let length: UInt32  // bytes

    init(header: FLACMetadataBlockHeader) {
        self.header = header
        length = header.metadataBlockDataSize
    }
}
