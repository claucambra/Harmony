//
//  FLACParser.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

class FLACParser {
    enum ParseError: Error {
        case dataNotFlac(String)
        case unexpectedEndError(String)
    }

    let data: Data

    var isFLAC: Bool {
        String(data: data[0..<4], encoding: .ascii) == FLACMetadata.streamMarker
    }

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> FLACMetadata {
        guard isFLAC else { throw ParseError.dataNotFlac("Cannot parse data, is not a FLAC!") }
        
        var currentData = data.advanced(by: 4)
        var streamInfo: FLACStreamInfoMetadataBlock?
        var vorbisComments: FLACVorbisCommentsMetadataBlock?
        var picture: FLACPictureMetadataBlock?
        var application: FLACApplicationMetadataBlock?
        var seekTable: FLACSeekTableMetadataBlock?
        var cueSheet: FLACCueSheetMetadataBlock?
        var paddings: [FLACPaddingMetadataBlock] = []

        while currentData.count >= FLACMetadataBlockHeader.size {
            let headerBytes = currentData[0..<FLACMetadataBlockHeader.size]
            let header = FLACMetadataBlockHeader(bytes: headerBytes)
            let blockEnd = FLACMetadataBlockHeader.size + Int(header.metadataBlockDataSize)

            guard currentData.count > blockEnd else {
                let errorString = "Currently parsed metadata block ends beyond the available data!"
                throw ParseError.unexpectedEndError(errorString)
            }
            
            currentData = currentData.advanced(by: FLACMetadataBlockHeader.size)

            switch header.metadataBlockType {
            case .streamInfo:
                streamInfo = FLACStreamInfoMetadataBlock(
                    bytes: currentData, header: header
                )
            case .padding:
                paddings.append(FLACPaddingMetadataBlock(header: header))
            case .application:
                application = FLACApplicationMetadataBlock(
                    bytes: currentData, header: header
                )
            case .seekTable:
                seekTable = FLACSeekTableMetadataBlock(bytes: currentData, header: header)
            case .vorbisComment:
                vorbisComments = FLACVorbisCommentsMetadataBlock(
                    bytes: currentData, header: header
                )
            case .cueSheet:
                cueSheet = FLACCueSheetMetadataBlock(bytes: currentData, header: header)
            case .picture:
                picture = FLACPictureMetadataBlock(bytes: currentData, header: header)
            case .reserved, .invalid, .undefined:
                print("Nothing to do")
            }

            currentData = currentData.advanced(by: Int(header.metadataBlockDataSize))

            if header.isLastMetadataBlock {
                return FLACMetadata(
                    streamInfo: streamInfo!,
                    vorbisComments: vorbisComments,
                    picture: picture,
                    application: application,
                    seekTable: seekTable,
                    cueSheet: cueSheet
                )
            }
        }

        let errorString = "Currently parsed metadata block ends beyond the available data!"
        throw ParseError.unexpectedEndError(errorString)
    }
}

