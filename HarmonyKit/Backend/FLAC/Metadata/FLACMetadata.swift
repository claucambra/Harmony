//
//  FLACMetadata.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

struct FLACMetadata {
    static var streamMarker = "fLaC"
    var streamInfo: FLACStreamInfoMetadataBlock?
    var vorbisComments: FLACVorbisCommentsMetadataBlock?
    var picture: FLACPictureMetadataBlock?
    var application: FLACApplicationMetadataBlock?
    var seekTable: FLACSeekTableMetadataBlock?
    var cueSheet: FLACCueSheetMetadataBlock?
    var paddings: [FLACPaddingMetadataBlock]?
}
