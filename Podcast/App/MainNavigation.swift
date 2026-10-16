//
//  MainNavigation.swift
//  Podcast
//

import SwiftUI
import UIKit

/// Library is the home screen; everything else (Search, Episodes, Saved,
/// Downloads) is pushed on top of it. There is no tab bar: the bottom of the
/// screen belongs to RootView's single bar (mini player + search).
struct MainNavigationRepresentable: UIViewControllerRepresentable {

    /// Space reserved at the bottom for the SwiftUI bar, so lists end above it
    /// instead of scrolling underneath (the old overlay problem).
    var bottomInset: CGFloat

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigation = UINavigationController(rootViewController: LibraryController())
        navigation.navigationBar.tintColor = .label
        AppNavigator.shared.navigationController = navigation
        return navigation
    }

    func updateUIViewController(_ navigation: UINavigationController, context: Context) {
        guard navigation.additionalSafeAreaInsets.bottom != bottomInset else { return }
        UIView.animate(withDuration: 0.3) {
            // Propagates to every pushed screen: scroll views adjust by themselves.
            navigation.additionalSafeAreaInsets.bottom = bottomInset
            navigation.view.layoutIfNeeded()
        }
    }
}
