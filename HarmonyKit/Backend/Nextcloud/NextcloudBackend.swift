//
//  NextcloudBackend.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 4/2/24.
//

import AVFoundation
import NextcloudKit
import OSLog

extension Logger {
    static let ncBackend = Logger(subsystem: subsystem, category: "ncBackend")
}

fileprivate let NextcloudWebDavFilesUrlSuffix: String = "/remote.php/dav/files/"

public class NextcloudBackend: NSObject, Backend {
    public let typeDescription: BackendDescription = ncBackendTypeDescription
    public let id: String
    public var presentation: BackendPresentable
    public var configValues: BackendConfiguration
    private let assetResourceLoaderDelegate: NextcloudAVAssetResourceLoaderDelegate
    private let ncKit: NextcloudKit
    private let ncKitBackground: NKBackground
    private let filesPath: String
    private let logger = Logger.ncBackend
    private let maxConcurrentScans = 4

    public required init(config: BackendConfiguration) {
        configValues = config
        id = config[BackendConfigurationIdFieldKey] as! String

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
            backendId: id,
            typeId: typeDescription.id,
            systemImage: typeDescription.systemImageName,
            primary: typeDescription.name,
            secondary: typeDescription.description,
            config: "URL: \(filesPath)"
        )
    }

    public func scan() async -> [Song] {
        Task { @MainActor in
            self.presentation.state = "Starting full scan..."
        }
        let songs = await recursiveScanRemotePath(filesPath)
        Task { @MainActor in
            self.presentation.state = "Finished full scan at \(Date().formatted())"
        }
        return songs
    }

    private func recursiveScanRemotePath(_ path: String) async -> [Song] {
        logger.debug("Starting read of: \(path)")
        Task { @MainActor in
            self.presentation.state = "Scanning \(path)..."
        }

        let readResult = await withCheckedContinuation { continuation in
            ncKit.readFileOrFolder(
                serverUrlFileName: path, depth: "1"
            ) { _, files, _, error in
                continuation.resume(returning: (files, error))
            }
        }

        let files = readResult.0
        let error = readResult.1

        guard error == .success else {
            logger.error("Could not scan \(path): \(error.errorDescription)")
            return []
        }

        guard !files.isEmpty else {
            logger.warning("Received no items from readFileOrFolder of \(path)")
            return []
        }

        let fileCount = files.count
        var songs: [Song] = []

        await withTaskGroup(of: [Song].self) { group in
            for i in 1..<fileCount { // First song is always the subject of the scan, not child
                // When we have submitted the maximum concurrent scans in the first burst, wait for
                // a task to finish off before submitting the next scan, thus limiting concurrent
                // tasks.
                if i >= self.maxConcurrentScans - 1 {
                    guard let scanResult = await group.next() else { continue }
                    songs.append(contentsOf: scanResult)
                }

                let file = files[i]
                let receivedFileUrl = file.serverUrl + "/" + file.fileName
                // We don't care about the metadata for the directory itself so skip it.
                guard receivedFileUrl != filesPath else { continue }
                logger.debug("Received file \(receivedFileUrl)")

                group.addTask(priority: .userInitiated) {
                    if file.directory {
                        return await self.recursiveScanRemotePath(receivedFileUrl)
                    } else if let song = await self.handleReadFile(
                        receivedFileUrl, ocId: file.ocId, etag: file.etag
                    ) {
                        return [song]
                    } else {
                        return []
                    }
                }
            }

            // Collects the remaining tasks not waited for in the in-loop throttling section (this
            // should only be the last task, which is not covered by the await group.next())
            for await scanResult in group {
                songs.append(contentsOf: scanResult)
            }
        }

        logger.info("Finished scan of \(path)")
        return songs
    }

    private func handleReadFile(
        _ receivedFileUrl: String, ocId: String, etag: String
    ) async -> Song? {
        // Process received file
        guard let songUrl = URL(string: receivedFileUrl) else {
            logger.error("Received serverUrl for \(receivedFileUrl) is invalid")
            return nil
        }

        guard fileHasPlayableExtension(fileURL: songUrl) else {
            logger.info("File at \(songUrl) is not a playable song file, skip")
            return nil
        }

        let asset = AVURLAsset(url: songUrl)
        asset.resourceLoader.setDelegate(assetResourceLoaderDelegate, queue: DispatchQueue.global())

        guard let song = await Song(
            url: songUrl, 
            asset: asset,
            identifier: ocId,
            backendId: self.id,
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

    public func assetForSong(_ song: Song) -> AVAsset? {
        let url = song.localUrl ?? song.url
        Logger.ncBackend.debug("Providing url \(url) for \(song.title)")
        let asset = AVURLAsset(url: url)
        asset.resourceLoader.setDelegate(assetResourceLoaderDelegate, queue: DispatchQueue.global())
        return asset
    }
    
    public func fetchSong(_ song: Song) async {
        guard let localUrl = localFileURL(song: song) else { return }
        let localPath = localUrl.path
        Logger.ncBackend.info("Downloading song for offline playback: \(song.url) to \(localPath)")

        await withCheckedContinuation { continuation in
            ncKit.download(
                serverUrlFileName: song.url, fileNameLocalPath: localPath
            ) { account, etag, date, length, allHeaderFields, nkError in
                guard nkError == .success else {
                    Logger.ncBackend.error("Download error: \(nkError.errorDescription)")
                    continuation.resume()
                    return
                }
                song.localUrl = localUrl
                Logger.ncBackend.debug("Successfully downloaded \(song.url) to \(localUrl)")
                continuation.resume()
            }
        }
    }
    
    public func evictSong(_ song: Song) async {
        guard let localUrl = localFileURL(song: song) else { return }
        Logger.ncBackend.info("Evicting song: \(song.url)")

        do {
            try FileManager.default.removeItem(at: localUrl)
            song.localUrl = nil
        } catch let error {
            Logger.ncBackend.error("Could not delete song \(song.url) at \(localUrl): \(error)")
        }
    }
}
