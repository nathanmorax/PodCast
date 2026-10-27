//
//  UIViewController+EpisodeSheet.swift
//  Podcast
//

import UIKit
import SwiftUI

extension UIViewController {

    /// An episode's details as a sheet (half screen, can grow to full):
    /// what tapping an episode row opens, from any list. Its Listen plays
    /// the episode and closes the sheet.
    ///
    /// (Tapping the row's ▶ plays it in the mini player instead, without
    /// opening anything.)
    func presentEpisodeSheet(_ episode: Episode) {
        let sheet = UIHostingController(rootView: EpisodeInfoSheet(episode: episode) { [weak self] in
            PlayerManager.shared.play(episode)
            self?.dismiss(animated: true)
        })
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
            presentation.preferredCornerRadius = 28
        }
        present(sheet, animated: true)
    }
}
