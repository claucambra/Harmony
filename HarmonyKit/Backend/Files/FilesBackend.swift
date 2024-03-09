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

    func songsFromLocalUrls(_ urls: [URL]) async -> [Song] {
        var songs: [Song] = []
        for url in urls {
            let asset = AVAsset(url: url)
            var song: Song?

            if FileManager.default.isUbiquitousItem(at: url) {  // This is an iCloud file
                Logger.defaultLog.debug("Found an iCloud file: \(url)")
                let isDownloaded = ubiquitousFileIsDownloaded(url: url)

                song = await Song(
                    url: url,
                    asset: asset,
                    identifier: url.absoluteString,  // TODO
                    backendId: id,
                    local: false,
                    downloadState: isDownloaded ? .downloaded : .notDownloaded,
                    versionId: url.absoluteString  // TODO
                )
            } else {
                guard let csum = calculateMD5Checksum(forFileAtLocalURL: url) else { continue }
                song = await Song(
                    url: url,
                    asset: asset,
                    identifier: csum,
                    backendId: id,
                    local: true,
                    downloadState: .downloaded,
                    versionId: csum
                )
            }
            guard let song = song else { continue }
            songs.append(song)
        }
        return songs
    }

    public func scan() async -> [Song] {
        Logger.filesBackend.info("Starting full scan of \(self.path)")
        DispatchQueue.main.async {
            self.presentation.scanning = true
            self.presentation.state = "Starting full scan..."
        }
        let urls = await recursiveScan(path: path)
        let songs = await songsFromLocalUrls(urls)
        DispatchQueue.main.async {
            self.presentation.scanning = false
            self.presentation.state = "Finished full scan at " + Date().formatted()
        }
        return songs
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
                Swift.debugPrint("*** Unable to access the contents of \(url.path) ***\n")
                return
            }

            for case let file as URL in fileList {
                Logger.filesBackend.debug("Found \(file) in \(path)")

                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory),
                   !isDirectory.boolValue,
                   filePlayability(fileURL: file) == .filePlayable 
                {
                    audioFiles.append(file)
                }
            }
        }

        return audioFiles
    }

    public func fetchSong(_ song: Song) async {
        guard song.downloadState != DownloadState.downloaded.rawValue else {
            Logger.defaultLog.info("Not downloading already downloaded song \(song.url)")
            return
        }
        guard song.downloadState != DownloadState.downloaded.rawValue else {
            Logger.ncBackend.info("Song already downloading \(song.url)")
            return
        }
        let fileManager = FileManager.default
        guard fileManager.isUbiquitousItem(at: song.url) else { return }
        do {
            Logger.defaultLog.debug("Fetching iCloud song: \(song.url)")
            song.downloadState = DownloadState.downloading.rawValue
            await startPollingDownloadState(forSong: song, endState: .downloaded)
            try fileManager.startDownloadingUbiquitousItem(at: song.url)
        } catch let error {
            Logger.defaultLog.error("Could not fetch iCloud song: \(error)")
        }
    }
    
    public func evictSong(_ song: Song) async {
        let fileManager = FileManager.default
        guard fileManager.isUbiquitousItem(at: song.url) else { return }
        do {
            Logger.defaultLog.debug("Evicting iCloud song: \(song.url)")
            await startPollingDownloadState(forSong: song, endState: .notDownloaded)
            try fileManager.evictUbiquitousItem(at: song.url)
        } catch let error {
            Logger.defaultLog.error("Could not evict iCloud song: \(error)")
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
            Logger.defaultLog.error("Could not get iCloud download status of \(url)")
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
