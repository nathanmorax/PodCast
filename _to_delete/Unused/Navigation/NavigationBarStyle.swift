//
//  NavigationBarStyle.swift
//  Podcast
//

import UIKit

/// The navigation bar's two looks, the same in every screen, and never a
/// hairline under it: UIKit's default bar draws a 1 px shadow line at its
/// bottom, which showed up while navigating (Library hides its bar, so
/// every push brought the default one back for a moment, line included).
@MainActor
enum NavigationBarStyle {

    /// Over a cover or a colored header: nothing behind the buttons.
    static let transparent: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        appearance.shadowImage = nil
        return appearance
    }()

    /// Content scrolled under it: the system's blur, without the line.
    static let solid: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = .clear
        appearance.shadowImage = nil
        return appearance
    }()

    /// Every stack's bar: transparent at the top of a page, solid once
    /// content goes under it. Screens may override it per item.
    static func applyDefault(to bar: UINavigationBar) {
        bar.standardAppearance = solid
        bar.compactAppearance = solid
        bar.scrollEdgeAppearance = transparent
        bar.compactScrollEdgeAppearance = transparent
    }

    /// One screen's bar, the same look in every state.
    static func apply(_ appearance: UINavigationBarAppearance, to item: UINavigationItem) {
        item.standardAppearance = appearance
        item.scrollEdgeAppearance = appearance
        item.compactAppearance = appearance
        item.compactScrollEdgeAppearance = appearance
    }
}
