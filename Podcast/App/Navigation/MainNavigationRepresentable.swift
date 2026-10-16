//
//  MainNavigationRepresentable.swift
//  Podcast
//

import SwiftUI
import UIKit

/// Wraps MainContainerController for RootView.
struct MainNavigationRepresentable: UIViewControllerRepresentable {

    /// Space reserved at the bottom for the SwiftUI bar, so lists end above it
    /// instead of scrolling underneath.
    var bottomInset: CGFloat

    func makeUIViewController(context: Context) -> MainContainerController {
        let container = MainContainerController()
        AppNavigator.shared.container = container
        return container
    }

    func updateUIViewController(_ container: MainContainerController, context: Context) {
        guard container.additionalSafeAreaInsets.bottom != bottomInset else { return }
        // Same curve as the bar itself (iOS 18 UIKit API with a SwiftUI
        // Animation), so lists resize in step with it.
        UIView.animate(AppAnimation.barVisibility) {
            // Propagates to both stacks and every pushed screen.
            container.additionalSafeAreaInsets.bottom = bottomInset
            container.view.layoutIfNeeded()
        }
    }
}
