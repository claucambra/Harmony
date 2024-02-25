//
//  FLACMetadata.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACMetadata {
    static var streamMarker = "fLaC"
    let streamInfo: FLACStreamInfoMetadataBlock
    let vorbisComments: FLACVorbisCommentsMetadataBlock?
    let picture: FLACPictureMetadataBlock?
    let application: FLACApplicationMetadataBlock?
    let seekTable: FLACSeekTableMetadataBlock?
    let cueSheet: FLACCueSheetMetadataBlock?
    let paddings: [FLACPaddingMetadataBlock] = []
}
