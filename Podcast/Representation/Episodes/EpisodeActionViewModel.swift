//
//  EpisodeActionViewModel.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//


import Observation

@Observable
final class EpisodeActionViewModel {

    private let playerManager: PlayerManager
    private let bookmarkManager: BookMarkEpisodeManager
    private let downloadManager: DownloadManager

    let episode: Episode

    init(
        episode: Episode,
        playerManager: PlayerManager = .shared,
        bookmarkManager: BookMarkEpisodeManager = .shared,
        downloadManager: DownloadManager = .shared
    ) {
        self.episode = episode
        self.playerManager = playerManager
        self.bookmarkManager = bookmarkManager
        self.downloadManager = downloadManager
    }

    // MARK: - Estado observable

    var isPlaying: Bool {
        playerManager.currentEpisode?.streamUrl == episode.streamUrl
        && playerManager.viewModel.isPlaying
    }

    var isBookmarked: Bool {
        bookmarkManager.isBookMarked(episode)
    }

    var downloadState: DownloadState {
        downloadManager.state(for: episode)
    }

    // MARK: - Acciones

    func playOrPause(presentation: PlayerManager.PlayerPresentation = .mini) {
        playerManager.playOrToggle(episode, presentation: presentation)
        print("Duration: ", episode)
    }

    func toggleBookmark() {
        bookmarkManager.toggle(episode)
    }

    func download() {
        downloadManager.download(episode)
    }
    
    func cancelDownload() {
        downloadManager.cancelDownload(episode)
    }
    
    func deleteDownload() {
        downloadManager.deleteDownload(episode)
    }
}
