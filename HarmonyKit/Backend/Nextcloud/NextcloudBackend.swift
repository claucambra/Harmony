//
//  NextcloudBackend.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 4/2/24.
//

import AVFoundation
import NextcloudCapabilitiesKit
import NextcloudKit
import OSLog
import SwiftData

extension Logger {
    static let ncBackend = Logger(subsystem: subsystem, category: "ncBackend")
}

fileprivate let NextcloudWebDavFilesUrlSuffix: String = "/remote.php/dav/files/"
fileprivate let NotifyPushWebSocketPingIntervalNanoseconds: UInt64 = 30 * 1_000_000
fileprivate let NotifyPushWebSocketPingFailLimit = 8
fileprivate let NotifyPushWebSocketAuthenticationFailLimit = 3

public class NextcloudBackend: 
    NSObject, Backend, NKCommonDelegate, URLSessionDelegate, URLSessionWebSocketDelegate
{
    public let typeDescription: BackendDescription = ncBackendTypeDescription
    public let backendId: String
    public var presentation: BackendPresentable
    public var configValues: BackendConfiguration
    private let assetResourceLoaderDelegate: NextcloudAVAssetResourceLoaderDelegate
    private let ncKit: NextcloudKit
    private let ncKitBackground: NKBackground
    private let filesPath: String
    private let logger = Logger.ncBackend
    private let maxConcurrentScans = 4
    private var capabilities: Capabilities?
    private var webSocketUrlSession: URLSession?
    private var webSocketTask: URLSessionWebSocketTask?
    private var webSocketOperationQueue = OperationQueue()
    private var webSocketPingFailCount = 0
    private var webSocketAuthenticationFailCount = 0
    private var scanTask: Task<(), Error>?
    private var networkReachability: NKCommon.TypeReachability = .unknown {
        didSet {
            if oldValue == .notReachable {
                reconnectWebSocket()
                NotificationCenter.default.post(
                    name: BackendNewScanRequiredNotification, object: self
                )
            }
        }
    }

    public required init(config: BackendConfiguration) {
        configValues = config
        backendId = config[BackendConfigurationIdFieldKey] as! String

        let user = config[NextcloudBackendFieldId.username.rawValue] as! String
        let password = config[NextcloudBackendFieldId.password.rawValue] as! String
        let serverUrl = config[NextcloudBackendFieldId.serverUrl.rawValue] as! String
        ncKit = NextcloudKit()
        ncKit.setup(user: user, userId: user, password: password, urlBase: serverUrl)
        ncKitBackground = NKBackground(nkCommonInstance: ncKit.nkCommonInstance)

        var davRelativePath = config[NextcloudBackendFieldId.musicPath.rawValue] as! String
        if davRelativePath.last == "/" {
            davRelativePath.removeLast()
        }
        filesPath = serverUrl + NextcloudWebDavFilesUrlSuffix + user + davRelativePath

        assetResourceLoaderDelegate = NextcloudAVAssetResourceLoaderDelegate(
            user: user, password: password
        )

        presentation = BackendPresentable(
            backendId: backendId,
            typeId: typeDescription.id,
            systemImage: typeDescription.systemImageName,
            primary: typeDescription.name,
            secondary: typeDescription.description,
            config: "URL: \(filesPath)"
        )

        super.init()
        reconnectWebSocket()
    }

    // MARK: - NKCommonDelegate implementation
    @objc public func networkReachabilityObserver(_ typeReachability: NKCommon.TypeReachability) {
        networkReachability = typeReachability
    }

    // MARK: - NotifyPush WebSocket handling
    private func reconnectWebSocket() {
        resetWebSocket()
        guard webSocketAuthenticationFailCount < NotifyPushWebSocketAuthenticationFailLimit else {
            Logger.ncBackend.error(
                "Exceeded authentication failures for notify push websocket \(self.backendId)"
            )
            return
        }
        guard networkReachability != .notReachable else {
            Logger.ncBackend.error("Network unreachable, will retry when reconnected")
            return
        }
        Task { await self.configureNotifyPush() }
    }

    private func resetWebSocket() {
        webSocketUrlSession = nil
        webSocketTask = nil
        webSocketOperationQueue.cancelAllOperations()
        webSocketOperationQueue.isSuspended = true
        webSocketPingFailCount = 0
    }

    private func configureNotifyPush() async {
        let capabilitiesData: Data? = await withCheckedContinuation { continuation in
            ncKit.getCapabilities { account, data, error in
                guard error == .success else {
                    Logger.ncBackend.error("Could not get \(self.backendId) capabilities: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: data)
            }
        }
        guard let capabilitiesData = capabilitiesData,
              let capabilities = Capabilities(data: capabilitiesData),
              let websocketEndpoint = capabilities.notifyPush?.endpoints?.websocket
        else {
            Logger.ncBackend.error("Could not get notifyPush websocket \(self.backendId)")
            return
        }

        guard let websocketEndpointUrl = URL(string: websocketEndpoint) else {
            Logger.ncBackend.error("Received notifyPush endpoint is invalid: \(websocketEndpoint)")
            return
        }
        webSocketOperationQueue.isSuspended = false
        webSocketUrlSession = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: self, 
            delegateQueue: webSocketOperationQueue
        )
        webSocketTask = webSocketUrlSession?.webSocketTask(with: websocketEndpointUrl)
        webSocketTask?.resume()
        Logger.ncBackend.info("Successfully configured push notifications for \(self.backendId)")
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let authMethod = challenge.protectionSpace.authenticationMethod
        Logger.ncBackend.debug("Received authentication challenge with method: \(authMethod)")
        if authMethod == NSURLAuthenticationMethodHTTPBasic {
            let credential = URLCredential(
                user: ncKit.nkCommonInstance.userId,
                password: ncKit.nkCommonInstance.password,
                persistence: .forSession
            )
            completionHandler(.useCredential, credential)
        } else if authMethod == NSURLAuthenticationMethodServerTrust {
            // TODO: Validate the server trust
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                Logger.ncBackend.warning("Received server trust auth challenge but no trust avail")
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            Logger.ncBackend.warning("Unhandled auth method: \(authMethod)")
            // Handle other authentication methods or cancel the challenge
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    public func urlSession(
        _ session: URLSession, 
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        Logger.ncBackend.debug("Websocket connected for \(self.backendId), sending auth details")
        Task { await authenticateWebSocket() }
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        Logger.ncBackend.debug("Socket connection closed for \(self.backendId).")
        if let reason = reason {
            Logger.ncBackend.debug("Reason: \(String(data: reason, encoding: .utf8) ?? "unknown")")
        }
        Logger.ncBackend.debug("Retrying websocket connection for \(self.backendId).")
        reconnectWebSocket()
    }

    private func authenticateWebSocket() async {
        do {
            try await webSocketTask?.send(.string(ncKit.nkCommonInstance.userId))
            try await webSocketTask?.send(.string(ncKit.nkCommonInstance.password))
        } catch let error {
            Logger.ncBackend.error("Error authenticating websocket for \(self.backendId): \(error)")
        }
        readWebSocket()
    }

    private func pingWebSocket() async {  // Keep the socket connection alive
        guard networkReachability != .notReachable else {
            Logger.ncBackend.error("Not pinging \(self.backendId) as network is unreachable")
            return
        }
        
        if let error = await withCheckedContinuation({ continuation in
            webSocketTask?.sendPing { error in
                continuation.resume(returning: error)
                return
            }
        }) {
            Logger.ncBackend.warning("Websocket ping failed: \(error)")
            webSocketPingFailCount += 1
            if webSocketPingFailCount > NotifyPushWebSocketPingFailLimit {
                reconnectWebSocket()
            } else {
                Task.detached { await self.pingWebSocket() }
            }
            return
        }

        // TODO: Stop on auth change
        do {
            try await Task.sleep(nanoseconds: NotifyPushWebSocketPingIntervalNanoseconds)
        } catch let error {
            Logger.ncBackend.error("Could not sleep websocket ping for \(self.backendId): \(error)")
        }
        Task.detached { await self.pingWebSocket() }
    }

    private func readWebSocket() {
        webSocketTask?.receive { result in
            switch result {
            case .failure:
                Logger.ncBackend.debug("Failed to read websocket for \(self.backendId)")
                self.reconnectWebSocket()
            case .success(let message):
                switch message {
                case .data(let data):
                    self.processWebsocket(data: data)
                case .string(let string):
                    self.processWebsocket(string: string)
                @unknown default:
                    Logger.ncBackend.error("Unknown case encountered while reading websocket!")
                }
                self.readWebSocket()
            }
        }
    }

    private func processWebsocket(data: Data) {
        guard let string = String(data: data, encoding: .utf8) else {
            Logger.ncBackend.error("Could not convert websocket data to string for id: \(self.backendId)")
            return
        }
        processWebsocket(string: string)
    }

    private func processWebsocket(string: String) {
        Logger.ncBackend.debug("Received websocket string: \(string)")
        if string == "notify_file" {
            Logger.ncBackend.debug("Received file notification for \(self.backendId)")
            NotificationCenter.default.post(name: BackendNewScanRequiredNotification, object: self)
        } else if string == "notify_activity" {
            Logger.ncBackend.debug("Received activity notification, ignoring: \(self.backendId)")
        } else if string == "notify_notification" {
            Logger.ncBackend.debug("Received notification notification, ignoring: \(self.backendId)")
        } else if string == "authenticated" {
            Logger.ncBackend.debug("Correctly authenticated websocket for \(self.backendId), pinging")
            Task.detached { await self.pingWebSocket() }
        } else if string == "err: Invalid credentials" {
            Logger.ncBackend.debug("Invalid creds for websocket for \(self.backendId), reattempting auth")
            webSocketAuthenticationFailCount += 1
            reconnectWebSocket()
        } else {
            Logger.ncBackend.warning("Received unknown string from websocket \(self.backendId): \(string)")
        }
    }

    // MARK: - Standard Backend protocol implementation
    public func scan(
        containerScanApprover: @Sendable @escaping (String, String) async -> Bool,
        songScanApprover: @Sendable @escaping (String, String) async -> Bool,
        finalisedSongHandler: @Sendable @escaping (Song) async -> Void,
        finalisedContainerHandler: @Sendable @escaping (Container, Container?) async -> Void
    ) async throws {
        Task { @MainActor in
            self.presentation.scanning = true
            self.presentation.state = "Starting full scan..."
        }
        scanTask = Task {
            try await recursiveScanRemotePath(
                filesPath,
                containerScanApprover: containerScanApprover,
                songScanApprover: songScanApprover,
                finalisedSongHandler: finalisedSongHandler,
                finalisedContainerHandler: finalisedContainerHandler,
                parentContainer: nil
            )
        }
        _ = try await scanTask!.value
        Task { @MainActor in
            self.presentation.scanning = false
        }

        if scanTask?.isCancelled == true {
            Task { @MainActor in
                self.presentation.state = "Full scan cancelled at " + Date().formatted()
            }
        } else {
            Task { @MainActor in
                self.presentation.state = "Finished full scan at " + Date().formatted()
            }
        }
    }

    private func recursiveScanRemotePath(
        _ path: String,
        containerScanApprover: @Sendable @escaping (String, String) async -> Bool,
        songScanApprover: @Sendable @escaping (String, String) async -> Bool,
        finalisedSongHandler: @Sendable @escaping (Song) async -> Void,
        finalisedContainerHandler: @Sendable @escaping (Container, Container?) async -> Void,
        parentContainer: Container?
    ) async throws {
        logger.debug("Starting read of: \(path)")
        Task { @MainActor in
            self.presentation.state = "Scanning \(path)..."
        }

        try Task.checkCancellation()
        let readResult = await withCheckedContinuation { continuation in
            ncKit.readFileOrFolder(
                serverUrlFileName: path, depth: "1"
            ) { _, files, _, error in
                continuation.resume(returning: (files, error))
            }
        }
        try Task.checkCancellation()

        let files = readResult.0
        let error = readResult.1

        guard error == .success else {
            logger.error("Could not scan \(path): \(error.errorDescription)")
            throw ScanError.generalError(error.errorDescription)
        }

        guard !files.isEmpty, let scannedDir = files.first else {
            logger.warning("Received no items from readFileOrFolder of \(path)")
            return
        }

        // This is the root scan
        if parentContainer == nil, await !containerScanApprover(scannedDir.ocId, scannedDir.etag) {
            logger.info("Not scanning root path")
            return
        }

        let container = Container(
            identifier: scannedDir.ocId,
            backendId: self.backendId,
            versionId: scannedDir.etag
        )
        let fileCount = files.count

        try await withThrowingTaskGroup(of: Int.self) { group in
            for i in 1..<fileCount { // First song is always the subject of the scan, not child
                // When we have submitted the maximum concurrent scans in the first burst, wait for
                // a task to finish off before submitting the next scan, thus limiting concurrent
                // tasks.
                try Task.checkCancellation()
                if i >= self.maxConcurrentScans - 1 {
                    guard let _ = try await group.next() else { continue }
                }

                let file = files[i]
                let receivedFileUrl = file.serverUrl + "/" + file.fileName
                // We don't care about the metadata for the directory itself so skip it.
                guard receivedFileUrl != filesPath else { continue }
                logger.debug("Received file \(receivedFileUrl)")

                group.addTask(priority: .userInitiated) {
                    if file.directory {
                        guard await containerScanApprover(file.ocId, file.etag) else { return 0 }
                        try await self.recursiveScanRemotePath(
                            receivedFileUrl,
                            containerScanApprover: containerScanApprover,
                            songScanApprover: songScanApprover,
                            finalisedSongHandler: finalisedSongHandler,
                            finalisedContainerHandler: finalisedContainerHandler,
                            parentContainer: container
                        )
                    } else if let song = try await self.handleReadFile(
                        receivedFileUrl, 
                        ocId: file.ocId,
                        etag: file.etag,
                        parentContainer: container,
                        songScanApprover: songScanApprover
                    ) {
                        await finalisedSongHandler(song)
                    }
                    return 0
                }
            }
        }

        logger.info("Finished scan of \(path)")
        await finalisedContainerHandler(container, parentContainer)
    }

    private func handleReadFile(
        _ receivedFileUrl: String, 
        ocId: String,
        etag: String,
        parentContainer: Container,
        songScanApprover: @Sendable @escaping (String, String) async -> Bool
    ) async throws -> Song? {
        // Process received file
        guard let songUrl = URL(string: receivedFileUrl) else {
            logger.error("Received serverUrl for \(receivedFileUrl) is invalid")
            return nil
        }

        guard fileHasPlayableExtension(fileURL: songUrl) else {
            logger.info("File at \(songUrl) is not a playable song file, skip")
            return nil
        }

        guard await songScanApprover(ocId, etag) else {
            logger.info("Not scanning song: \(ocId)")
            return nil
        }

        try Task.checkCancellation()
        let asset = AVURLAsset(url: songUrl)
        asset.resourceLoader.setDelegate(assetResourceLoaderDelegate, queue: DispatchQueue.global())

        guard let song = await Song(
            url: songUrl, 
            asset: asset,
            identifier: ocId,
            parentContainerId: parentContainer.identifier,
            backendId: self.backendId,
            local: false,
            versionId: etag,
            fetchSession: ncKit.sessionManager,
            fetchHeaders: ncKit.nkCommonInstance.getStandardHeaders(options: NKRequestOptions())
        ) else {
            logger.error("Could not create song from \(receivedFileUrl)")
            return nil
        }

        logger.debug("Acquired valid song: \(songUrl)")
        return song
    }

    public func cancelScan() {
        Logger.ncBackend.info("Cancelling scan for \(self.backendId)")
        scanTask?.cancel()
        ncKit.sessionManager.session.getTasksWithCompletionHandler {
            (dataTasks, uploadTasks, downloadTasks) in
            dataTasks.forEach { $0.cancel() }
        }
    }

    public func assetForSong(_ song: Song) -> AVAsset? {
        var url = song.url
        if song.downloadState == DownloadState.downloaded.rawValue,
            let localUrl = localFileURL(song: song)
        {
            url = localUrl
        } // TODO: Reset downloaded state here if file not found
        Logger.ncBackend.debug("Providing url \(url) for \(song.title)")
        let asset = AVURLAsset(url: url)
        asset.resourceLoader.setDelegate(assetResourceLoaderDelegate, queue: DispatchQueue.global())
        return asset
    }
    
    public func fetchSong(_ song: Song) async {
        guard song.downloadState != DownloadState.downloaded.rawValue else {
            Logger.ncBackend.info("Not downloading already downloaded song \(song.url)")
            return
        }
        guard song.downloadState != DownloadState.downloading.rawValue else {
            Logger.ncBackend.info("Song already downloading \(song.url)")
            return
        }
        guard let localUrl = localFileURL(song: song) else {
            Logger.ncBackend.error("Unable to get prospective local url for song \(song.url)")
            return
        }
        let localPath = localUrl.path
        Logger.ncBackend.info("Downloading song for offline playback: \(song.url) to \(localPath)")

        await withCheckedContinuation { continuation in
            ncKit.download(
                serverUrlFileName: song.url, 
                fileNameLocalPath: localPath,
                progressHandler: { progress in
                    song.downloadState = DownloadState.downloading.rawValue
                    song.downloadProgress = progress.fractionCompleted
                },
                completionHandler: { account, etag, date, length, allHeaderFields, nkError in
                    guard nkError == .success else {
                        Logger.ncBackend.error("Download error: \(nkError.errorDescription)")
                        song.downloadState = DownloadState.notDownloaded.rawValue
                        continuation.resume()
                        return
                    }
                    song.downloadState = DownloadState.downloaded.rawValue
                    Logger.ncBackend.debug("Successfully downloaded \(song.url) to \(localUrl)")
                    continuation.resume()
            })
        }
    }
    
    public func evictSong(_ song: Song) async {
        guard let localUrl = localFileURL(song: song) else { return }
        Logger.ncBackend.info("Evicting song: \(song.url)")

        do {
            try FileManager.default.removeItem(at: localUrl)
            Task { @MainActor in
                song.downloadState = DownloadState.notDownloaded.rawValue
            }
        } catch let error {
            Logger.ncBackend.error("Could not delete song \(song.url) at \(localUrl): \(error)")
        }
    }
}
