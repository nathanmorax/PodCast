//
//  EpisodeContextMenuButton.swift
//  Podcast
//
//  Created by Jonathan Jesus on 09/06/26.
//
import SwiftUI

struct EpisodeContextMenuButton: UIViewRepresentable {
    let viewModel: EpisodeActionViewModel
    /// "Details" at the top of the menu (hidden when nil).
    var onInfo: (() -> Void)? = nil

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
        context.coordinator.onInfo = onInfo
        uiView.menu = context.coordinator.makeMenu()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, onInfo: onInfo)
    }

    class Coordinator: NSObject {
        var viewModel: EpisodeActionViewModel
        var onInfo: (() -> Void)?

        init(viewModel: EpisodeActionViewModel, onInfo: (() -> Void)?) {
            self.viewModel = viewModel
            self.onInfo = onInfo
        }

        @MainActor func makeMenu() -> UIMenu {
            let download = UIAction(
                title: String(localized: "Download"),
                image: UIImage(systemName: "arrow.down.circle")
            ) { [weak self] _ in
                self?.viewModel.download()
            }

            let bookmarkTitle = viewModel.isBookmarked ? String(localized: "Remove bookmark") : String(localized: "Save")
            let bookmarkIcon  = viewModel.isBookmarked ? "bookmark.slash.fill" : "bookmark.fill"
            let bookmark = UIAction(
                title: bookmarkTitle,
                image: UIImage(systemName: bookmarkIcon)
            ) { [weak self] _ in
                self?.viewModel.toggleBookmark()
            }

            var items: [UIMenuElement] = []
            if onInfo != nil {
                items.append(UIAction(
                    title: String(localized: "Details"),
                    image: UIImage(systemName: "info.circle")
                ) { [weak self] _ in
                    self?.onInfo?()
                })
            }
            items += [download, bookmark]
            return UIMenu(children: items)
        }
    }
}
