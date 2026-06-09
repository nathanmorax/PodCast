//
//  EpisodeContextMenuButton.swift
//  Podcast
//
//  Created by Jonathan Jesus on 09/06/26.
//
import SwiftUI

struct EpisodeContextMenuButton: UIViewRepresentable {
    let viewModel: EpisodeActionViewModel

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        button.tintColor = .black
        button.showsMenuAsPrimaryAction = true  // ← abre el menú con tap, sin long press
        button.menu = context.coordinator.makeMenu()
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        context.coordinator.viewModel = viewModel
        uiView.menu = context.coordinator.makeMenu()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject {
        var viewModel: EpisodeActionViewModel

        init(viewModel: EpisodeActionViewModel) {
            self.viewModel = viewModel
        }

        func makeMenu() -> UIMenu {
            let download = UIAction(
                title: "Descargar",
                image: UIImage(systemName: "arrow.down.circle")
            ) { [weak self] _ in
                self?.viewModel.download()
            }

            let bookmarkTitle = viewModel.isBookmarked ? "Quitar guardado" : "Guardar"
            let bookmarkIcon  = viewModel.isBookmarked ? "bookmark.slash.fill" : "bookmark.fill"
            let bookmark = UIAction(
                title: bookmarkTitle,
                image: UIImage(systemName: bookmarkIcon)
            ) { [weak self] _ in
                self?.viewModel.toggleBookmark()
            }

            return UIMenu(children: [download, bookmark])
        }
    }
}
