//
//  AlbumDetailView.swift
//  Harmony
//
//  Created by Claudio Cambra on 1/3/24.
//

import HarmonyKit
import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    let sortedSongs: [Song]

    #if os(macOS)
    let horizontalPadding = UIMeasurements.ultraLargePadding
    let verticalPadding = UIMeasurements.veryLargePadding
    let buttonsAlongsideArtwork = true
    let albumTitleFont = Font.largeTitle
    let albumArtistFont = Font.title
    #else
    let horizontalPadding = UIMeasurements.largePadding
    let verticalPadding = UIMeasurements.largePadding
    let buttonsAlongsideArtwork = UIDevice.current.userInterfaceIdiom != .phone
    let albumTitleFont: Font = UIDevice.current.userInterfaceIdiom == .phone ? .title2 : .title
    let albumArtistFont: Font = UIDevice.current.userInterfaceIdiom == .phone ? .title3 : .title2
    #endif

    @State var artworkWidth: CGFloat = 0.0
    @State var selection: Set<Song.ID> = []

    init(album: Album) {
        self.album = album
        sortedSongs = sortedAlbumSongs(album)
    }

    var body: some View {
        let albumSongCount = album.songs.count
        let albumSongCountString = albumSongCount == 1 
            ? "\(albumSongCount) song"
            : "\(albumSongCount) songs"
        let albumTotalDuration = album.songs.reduce(0, { x, song in
            x + song.duration
        })
        let albumDuration = Duration
            .seconds(albumTotalDuration)
            .formatted(.time(pattern: .minuteSecond))

        List(selection: $selection) {
            AlbumHeaderView(album: album)
                .listRowInsets(.init(
                    top: verticalPadding,
                    leading: horizontalPadding,
                    bottom: verticalPadding,
                    trailing: horizontalPadding
                ))
                .listRowSeparator(.hidden)
                .selectionDisabled()
                .frame(maxWidth: .infinity)
                .contextMenu { AlbumContextMenuItems(album: album) }

            ForEach(sortedSongs) { song in
                SongListItemView(
                    song: song,
                    displayArtwork: false,
                    displayArtist: false,
                    displayTrackNumber: true
                )
                .listRowInsets(.init(
                    top: UIMeasurements.smallPadding,
                    leading: horizontalPadding,
                    bottom: UIMeasurements.smallPadding,
                    trailing: horizontalPadding
                ))
            }

            Text("\(albumSongCountString), \(albumDuration) minutes")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .listRowSeparator(.hidden, edges: [.bottom])
                .listRowInsets(.init(
                    top: verticalPadding,
                    leading: horizontalPadding,
                    bottom: verticalPadding,
                    trailing: horizontalPadding
                ))
                .selectionDisabled()
        }
        .listStyle(.plain)
        .contextMenu(forSelectionType: Song.ID.self) { items in
            contextMenuItemsForSongs(ids: items, songs: sortedSongs)
        } primaryAction: { ids in
            playSongsFromIds(ids, songs: sortedSongs)
        }
    }

    @ViewBuilder @MainActor
    var playButton: some View {
        Button {
            playAlbum(album)
        } label: {
            Label("Play", systemImage: "play.fill")
                .foregroundStyle(.primary)
            #if os(macOS)
                .padding([.leading, .trailing], UIMeasurements.largePadding)
            #endif
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    @ViewBuilder
    var downloadButton: some View {
        Button {
            fetchAlbum(album)
        } label: {
            DownloadStateLabelView(
                state: album.downloaded
                    ? DownloadState.downloaded.rawValue
                    : DownloadState.notDownloaded.rawValue
            )
        }
        .buttonStyle(.borderless)
    }
}
