//
//  FLACRemoteMetadataFetcher.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 23/2/24.
//

import Alamofire
import Foundation
import OSLog

class FLACRemoteMetadataFetcher {
    let session: Alamofire.Session
    let headers: HTTPHeaders?
    let url: URL
    private let queue = DispatchQueue(label: "flacRemoteMetadataFetcherQueue", qos: .userInitiated)
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!, category: "flacRemoteMetadataFetcher"
    )

    init(url: URL, session: Alamofire.Session, headers: HTTPHeaders?) {
        self.url = url
        self.session = session
        self.headers = headers
    }

    func fetch() async -> FLACMetadata? {
        return await withCheckedContinuation { continuation in
            var metadata: FLACMetadata?
            var gatheredData = Data()

            session
                .streamRequest(url, headers: headers)
                .responseStream(on: queue) { stream in
                    switch stream.event {
                    case let .stream(result):
                        switch result {
                        case let .success(data):
                            gatheredData.append(data)
                            let acquiredMetadata = self.handleCurrentData(
                                gatheredData, stream: stream, continuation: continuation
                            )
                            metadata = acquiredMetadata
                        case .failure(_):
                            self.logger.error("Stream failure! \(self.url)")
                        }
                    case let .complete(completion):
                        let error = String(describing: completion.error)
                        let metrics = String(describing: completion.metrics)
                        self.logger.debug("STREAM COMPLETED \(self.url) \(error) \(metrics)")
                        continuation.resume(returning: metadata)
                    }
                }
        }
    }

    private func handleCurrentData(
        _ gatheredData: Data,
        stream: Alamofire.DataStreamRequest.Stream<Data, Never>,
        continuation: CheckedContinuation<FLACMetadata?, Never>
    ) -> FLACMetadata? {
        if gatheredData.count <= 4 {
            return nil
        }

        let parser = FLACParser(data: gatheredData)
        do {
            let metadata = try parser.parse()
            logger.debug("Successfully parsed metadata. \(self.url)")
            stream.cancel()
            return metadata
        } catch FLACParser.ParseError.dataNotFlac {
            logger.error("Data stream is not a FLAC! \(gatheredData.count) \(self.url)")
            stream.cancel()
        } catch FLACParser.ParseError.unexpectedEndError {
            logger.debug("Full FLAC metadata not yet received, downloading more. \(self.url)")
        } catch {
            logger.error("Unknown error with current data, continuing \(self.url)")
        }

        return nil
    }
}
