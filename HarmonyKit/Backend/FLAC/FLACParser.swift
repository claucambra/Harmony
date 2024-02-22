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

        while currentData.count >= FLACMetadataBlockHeader.size {
            let headerBytes = currentData[0..<FLACMetadataBlockHeader.size]
            let header = FLACMetadataBlockHeader(bytes: headerBytes)
            let blockEnd = FLACMetadataBlockHeader.size + Int(header.metadataBlockDataSize)

            guard currentData.count > blockEnd else {
                let errorString = "Currently parsed metadata block ends beyond the available data!"
                throw ParseError.unexpectedEndError(errorString)
            }
            
            currentData = currentData.advanced(by: FLACMetadataBlockHeader.size)

            var metadata = FLACMetadata()
            switch header.metadataBlockType {
            case .streamInfo:
                metadata.streamInfo = FLACStreamInfoMetadataBlock(
                    bytes: currentData, header: header
                )
            case .padding:
                metadata.paddings.append(FLACPaddingMetadataBlock(header: header))
            case .application:
                metadata.application = FLACApplicationMetadataBlock(
                    bytes: currentData, header: header
                )
            case .seekTable:
                metadata.seekTable = FLACSeekTableMetadataBlock(bytes: currentData, header: header)
            case .vorbisComment:
                metadata.vorbisComments = FLACVorbisCommentsMetadataBlock(
                    bytes: currentData, header: header
                )
            case .cueSheet:
                metadata.cueSheet = FLACCueSheetMetadataBlock(bytes: currentData, header: header)
            case .picture:
                metadata.picture = FLACPictureMetadataBlock(bytes: currentData, header: header)
            case .reserved:
                continue
            case .invalid, .undefined:
                continue
            }

            currentData = currentData.advanced(by: Int(header.metadataBlockDataSize))

            if header.isLastMetadataBlock {
                return metadata
            }
        }

        let errorString = "Currently parsed metadata block ends beyond the available data!"
        throw ParseError.unexpectedEndError(errorString)
    }
}

