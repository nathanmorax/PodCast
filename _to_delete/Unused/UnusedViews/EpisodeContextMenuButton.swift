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
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        button.tintColor = .label
        button.showsMenuAsPrimaryAction = true  // ← abre el menú con tap, sin long press
        button.menu = context.coordinator.makeMenu()
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        context.coordinator.viewModel = viewModel
        context.coordinator.onInfo = onInfo
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, onInfo: onInfo)
    }

    @MainActor
    final class Coordinator: NSObject {
        var viewModel: EpisodeActionViewModel
        var onInfo: (() -> Void)?

        init(viewModel: EpisodeActionViewModel, onInfo: (() -> Void)?) {
            self.viewModel = viewModel
            self.onInfo = onInfo
        }

        /// Built each time it opens (EpisodeMenu), so it matches the
        /// episode now.
        func makeMenu() -> UIMenu {
            EpisodeMenu.make { [weak self] in
                guard let self else { return [] }
                return EpisodeMenu.items(for: self.viewModel, onInfo: self.onInfo)
            }
        }
    }
}
