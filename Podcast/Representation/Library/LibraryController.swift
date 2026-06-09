//
//  LibraryController.swift
//  Podcast
//
//  Created by Jonathan Jesus on 09/06/26.
//


import UIKit
import SwiftUI

final class LibraryController: UIViewController {

    private let actions = LibraryActions()
    private var hostingController: UIHostingController<LibraryView>?
    private var eventsTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHosting()
        listenNavigationEvents()
    }
    
    deinit {
        eventsTask?.cancel()
    }

    private func setupHosting() {
        let libraryView = LibraryView(actions: actions)
        let hosting = UIHostingController(rootView: libraryView)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = view.backgroundColor
        addChild(hosting)
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
    }

    // MARK: - Navigation
    
    private func listenNavigationEvents() {
        
        eventsTask = Task { [weak self] in
            guard let self else { return }
            
            for await destination in self.actions.events {
                guard !Task.isCancelled else { return }
                await self.navigate(to: destination)
            }
        }
        
    }

    @MainActor
    private func navigate(to destination: LibraryDestination) {
        switch destination {
        case .guardados:
            navigationController?.pushViewController(BookMarkEpisodeController(), animated: true)
        case .descargas:
            navigationController?.pushViewController(DownloadEpisodeViewController(), animated: true)
        case .podcast(let id):
            openPodcast(id: id)
//        case .programas, .canales, .categorias, .episodiosRecientes:
//            break // pantallas pendientes
        }
    }

    private func openPodcast(id: Int) {
        // Cuando tengas el Podcast por id:
        // let vc = EpisodesController()
        // vc.podcast = podcast
        // navigationController?.pushViewController(vc, animated: true)
    }
}
