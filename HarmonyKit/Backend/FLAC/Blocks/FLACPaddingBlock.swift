//
//  FLACPaddingBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACPaddingBlock {
    public let header: FLACMetadata.Header
    public let length: UInt32  // bytes
}
