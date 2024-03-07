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
        sortedSongs = album.songs.sorted {
            guard $0.trackNumber != 0, $1.trackNumber != 0 else { return $0.title < $1.title }
            return $0.trackNumber < $1.trackNumber
        }
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
            HStack(spacing: UIMeasurements.largePadding) {
                ColouredShadowArtworkView(artwork: album.artwork)
                    .frame(maxHeight: UIMeasurements.largeArtworkHeight)
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
                        playButton
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: artworkWidth)
            }
            .listRowInsets(.init(
                top: verticalPadding,
                leading: horizontalPadding,
                bottom: verticalPadding,
                trailing: horizontalPadding
            ))
            .listRowSeparator(.hidden)

            if !buttonsAlongsideArtwork {
                playButton
                    .listRowInsets(.init(
                        top: 0,
                        leading: horizontalPadding,
                        bottom: verticalPadding,
                        trailing: horizontalPadding
                    ))
                    .listRowSeparator(.hidden)
                    .frame(width: artworkWidth)
            }

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
            guard let firstSong = album.songs.first else { return }
            let controller = PlayerController.shared
            controller.playSong(firstSong, withinSongs: sortedSongs)
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
}
