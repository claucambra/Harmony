//
//  FilesBackend.swift
//  Harmony
//
//  Created by Claudio Cambra on 16/1/24.
//

import AVFoundation
import CryptoKit
import OSLog

extension Logger {
    static let filesBackend = Logger(subsystem: subsystem, category: "filesBackend")
}

// TODO: Find a way to do container versioning?
public class FilesBackend: NSObject, Backend {
    public let typeDescription = filesBackendTypeDescription
    public let id: String
    public var configValues: BackendConfiguration = [:]
    public private(set) var presentation: BackendPresentable
    public private(set) var path: URL {
        didSet { DispatchQueue.main.async { self.presentation.config = self.path.path } }
    }

    static func getPathFromConfig(_ config: BackendConfiguration) -> URL {
        let pathConfigFieldId = FilesBackendFieldId.pathConfig.rawValue
        #if os(macOS)
        let accessibleUrlPathFieldId =
            pathConfigFieldId + BackendConfigurationLocalURLAccessibleURLFieldKeySuffix
        if let accessibleUrl = config[accessibleUrlPathFieldId] as? URL {
            return accessibleUrl
        }
        #endif
        return URL(fileURLWithPath: config[pathConfigFieldId] as? String ?? "")
    }

    required public init(config: BackendConfiguration) {
        configValues = config
        let localPath = FilesBackend.getPathFromConfig(config)
        path = localPath
        id = config[BackendConfigurationIdFieldKey] as! String
        presentation = BackendPresentable(
            backendId: id,
            typeId: filesBackendTypeDescription.id,
            systemImage: filesBackendTypeDescription.systemImageName,
            primary: filesBackendTypeDescription.name,
            secondary: filesBackendTypeDescription.description,
            config: "Path: " + localPath.path
        )
        super.init()
        configurePath()
    }

    public init(path: URL, id: String) {
        self.path = path
        self.id = id
        presentation = BackendPresentable(
            backendId: id,
            typeId: filesBackendTypeDescription.id,
            systemImage: filesBackendTypeDescription.systemImageName,
            primary: filesBackendTypeDescription.name,
            secondary: filesBackendTypeDescription.description,
            config: "Path: " + path.path
        )
        super.init()
        configurePath()
    }

    deinit {
        path.stopAccessingSecurityScopedResource()
    }

    func configurePath() {
        guard path.startAccessingSecurityScopedResource() else {
            let errorString = "could not access security scoped resource."
            Logger.filesBackend.error("Error scanning directory \(self.path): \(errorString)")
            return
        }
    }

    func songsFromLocalUrls(
        _ urls: [URL],
        songScanApprover: @Sendable @escaping (String, String) async -> Bool,
        finalisedSongHandler: @Sendable @escaping (Song) async -> Void
    ) async {
        var containerUrls: Set<URL> = []
        for url in urls {
            let containerUrl = url.deletingLastPathComponent()
            containerUrls.insert(containerUrl)

            let asset = AVAsset(url: url)
            var song: Song?

            if FileManager.default.isUbiquitousItem(at: url) {  // This is an iCloud file
                Logger.defaultLog.debug("Found an iCloud file: \(url)")
                let isDownloaded = ubiquitousFileIsDownloaded(url: url)
                let identifier = url.absoluteString // TODO
                let versionId = url.absoluteString  // TODO

                guard await songScanApprover(identifier, versionId) else {
                    Logger.filesBackend.debug("Skipping \(url) scan, not approved")
                    continue
                }
                song = await Song(
                    url: url,
                    asset: asset,
                    identifier: identifier,
                    parentContainerId: path.path,
                    backendId: id,
                    local: false,
                    downloadState: isDownloaded ? .downloaded : .notDownloaded,
                    versionId: versionId
                )
            } else {
                let fm = FileManager.default
                let attributes = try? fm.attributesOfItem(atPath: url.path) as NSDictionary
                guard let songId = attributes?.fileSystemFileNumber().description,
                      let versionId = attributes?.fileModificationDate()?.description,
                      await songScanApprover(songId, versionId)
                else {
                    Logger.filesBackend.debug("Skipping \(url) scan")
                    continue
                }
                song = await Song(
                    url: url,
                    asset: asset,
                    identifier: songId,
                    parentContainerId: path.path,
                    backendId: id,
                    local: true,
                    downloadState: .downloaded,
                    versionId: versionId
                )
            }
            guard let song = song else { continue }
            await finalisedSongHandler(song)
        }
    }

    public func scan(
        containerScanApprover: @Sendable @escaping (String, String) async -> Bool,
        songScanApprover: @Sendable @escaping (String, String) async -> Bool,
        finalisedSongHandler: @Sendable @escaping (Song) async -> Void,
        finalisedContainerHandler: @Sendable @escaping (Container, Container?) async -> Void
    ) async {
        Logger.filesBackend.info("Starting full scan of \(self.path)")
        Task { @MainActor in
            self.presentation.scanning = true
            self.presentation.state = "Starting full scan..."
        }
        let urls = await recursiveScan(path: path)
        await songsFromLocalUrls(
            urls,
            songScanApprover: songScanApprover,
            finalisedSongHandler: finalisedSongHandler
        )
        Task { @MainActor in
            self.presentation.scanning = false
            self.presentation.state = "Finished full scan at " + Date().formatted()
        }
    }

    func recursiveScan(path: URL) async -> [URL] {
        Logger.filesBackend.info("Scanning \(path)")
        Task { @MainActor in
            self.presentation.state = "Scanning " + path.path + "…"
        }

        // Use file coordination for reading and writing any of the URL’s content.
        var audioFiles: [URL] = []
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: path, error: &error) { url in
            // Get an enumerator for the directory's content.
            guard let fileList = FileManager.default.enumerator(
                at: url, includingPropertiesForKeys: [.isDirectoryKey]
            ) else {
                Logger.filesBackend.error("Unable to access the contents of \(url.path)")
                return
            }

            for case let file as URL in fileList {
                Logger.filesBackend.debug("Found \(file) in \(path)")

                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory),
                   !isDirectory.boolValue,
                   filePlayability(fileURL: file) == .filePlayable 
                {
                    // TODO: Use song scanner here?
                    audioFiles.append(file)
                }
            }
        }
        return audioFiles
    }

    public func fetchSong(_ song: Song) async {
        guard song.downloadState != DownloadState.downloaded.rawValue else {
            Logger.filesBackend.info("Not downloading already downloaded song \(song.url)")
            return
        }
        guard song.downloadState != DownloadState.downloaded.rawValue else {
            Logger.filesBackend.info("Song already downloading \(song.url)")
            return
        }
        let fileManager = FileManager.default
        guard fileManager.isUbiquitousItem(at: song.url) else { return }
        do {
            Logger.filesBackend.debug("Fetching iCloud song: \(song.url)")
            song.downloadState = DownloadState.downloading.rawValue
            await startPollingDownloadState(forSong: song, endState: .downloaded)
            try fileManager.startDownloadingUbiquitousItem(at: song.url)
        } catch let error {
            Logger.filesBackend.error("Could not fetch iCloud song: \(error)")
        }
    }
    
    public func evictSong(_ song: Song) async {
        let fileManager = FileManager.default
        guard fileManager.isUbiquitousItem(at: song.url) else { return }
        do {
            Logger.filesBackend.debug("Evicting iCloud song: \(song.url)")
            await startPollingDownloadState(forSong: song, endState: .notDownloaded)
            try fileManager.evictUbiquitousItem(at: song.url)
        } catch let error {
            Logger.filesBackend.error("Could not evict iCloud song: \(error)")
        }
    }

    public func assetForSong(_ song: Song) -> AVAsset? {
        return AVAsset(url: song.url)
    }

    private func ubiquitousFileIsDownloaded(url: URL) -> Bool {
        let nsurl = url as NSURL
        var downloadedStatusValue: AnyObject? =
            URLUbiquitousItemDownloadingStatus.downloaded.rawValue as AnyObject
        do {
            try nsurl.getResourceValue(
                &downloadedStatusValue, forKey: URLResourceKey.ubiquitousItemDownloadingStatusKey
            )
        } catch {
            Logger.filesBackend.error("Could not get iCloud download status of \(url)")
        }

        let downloadedStatus = downloadedStatusValue as! String
        return downloadedStatus != URLUbiquitousItemDownloadingStatus.notDownloaded.rawValue
    }

    @MainActor
    private func startPollingDownloadState(
        forSong song: Song, 
        endState: URLUbiquitousItemDownloadingStatus?
    ) {
        // Since we do not use the document picker to select files we cannot use NSMetadataQuery
        // and have to resort to manually polling the state of the file until completion of the
        // download
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.ubiquitousFileIsDownloaded(url: song.url) {
                song.downloadState = DownloadState.downloaded.rawValue
                if endState == URLUbiquitousItemDownloadingStatus.downloaded ||
                    endState == URLUbiquitousItemDownloadingStatus.current {
                    timer.invalidate()
                }
            } else {
                song.downloadState = DownloadState.notDownloaded.rawValue
                if endState == URLUbiquitousItemDownloadingStatus.notDownloaded {
                    timer.invalidate()
                }
                // The download has not yet finished. Normally we would invoke the progressHandler.
                // With iCloud this comes with a caveat, which is that we cannot track the
                // progress of the download as we cannot use NSMetadataQuery.
                // So no progress recording.
            }
        }
    }
}
