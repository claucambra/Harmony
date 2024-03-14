//
//  AlbumHeaderView.swift
//  Harmony
//
//  Created by Claudio Cambra on 14/3/24.
//

import HarmonyKit
import SwiftUI

struct AlbumHeaderView: View {
    let album: Album

    #if os(macOS)
    private let horizontalPadding = UIMeasurements.ultraLargePadding
    private let verticalPadding = UIMeasurements.veryLargePadding
    private let buttonsAlongsideArtwork = true
    private let albumTitleFont = Font.largeTitle
    private let albumArtistFont = Font.title
    #else
    private let horizontalPadding = UIMeasurements.largePadding
    private let verticalPadding = UIMeasurements.largePadding
    private let buttonsAlongsideArtwork = UIDevice.current.userInterfaceIdiom != .phone
    private let albumTitleFont: Font = UIDevice.current.userInterfaceIdiom == .phone ? .title2 : .title
    private let albumArtistFont: Font = UIDevice.current.userInterfaceIdiom == .phone ? .title3 : .title2
    #endif

    @State var minArtworkWidth = 0.0
    @State var maxArtworkWidth = UIMeasurements.largeArtworkHeight
    @State private var artworkWidth: CGFloat = 0.0

    var body: some View {
        VStack(spacing: UIMeasurements.largePadding) {
            HStack(spacing: UIMeasurements.largePadding) {
                ColouredShadowArtworkView(artwork: album.artwork)
                    .frame(
                        minWidth: minArtworkWidth,
                        maxWidth: maxArtworkWidth,
                        minHeight: minArtworkWidth,
                        maxHeight: maxArtworkWidth
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .background {
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(.clear)
                                .onAppear { artworkWidth = proxy.size.width }
                                .onChange(of: proxy.size) { artworkWidth = proxy.size.width }
                        }
                    }

                VStack(alignment: .leading) {
                    Spacer()
                    Text(album.title.isEmpty ? "Unknown album" : album.title)
                        .font(albumTitleFont)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(album.artist ?? "Unknown artist")
                        .font(albumArtistFont)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(album.genre == nil || album.genre!.isEmpty
                         ? "Unknown genre"
                         : album.genre ?? "Unknown genre")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    if buttonsAlongsideArtwork {
                        HStack {
                            playButton
                            playNextButton
                            Spacer()
                            downloadButton
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxHeight: artworkWidth)
            }
            if !buttonsAlongsideArtwork {
                HStack {
                    playButton
                        .frame(width: artworkWidth)
                    Spacer()
                    downloadButton
                }
            }
        }
    }

    @ViewBuilder @MainActor
    private var playButton: some View {
        Button {
            playAlbum(album)
        } label: {
            Label("Play", systemImage: "play.fill")
                .foregroundStyle(.primary)
            #if os(macOS)
                .padding([.leading, .trailing], UIMeasurements.largePadding)
            #endif
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    @ViewBuilder @MainActor
    private var playNextButton: some View {
        Button {
            playNextAlbum(album)
        } label: {
            Label("Play next", systemImage: "text.line.first.and.arrowtriangle.forward")
                .padding([.leading, .trailing], UIMeasurements.largePadding)
        }
        .buttonStyle(.borderless)
        .controlSize(.large)
    }

    @ViewBuilder
    private var downloadButton: some View {
        Button {
            let songs = album.songs
            for song in songs {
                let backend = BackendsModel.shared.backends[song.backendId]
                Task { await backend?.fetchSong(song) }
            }
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
