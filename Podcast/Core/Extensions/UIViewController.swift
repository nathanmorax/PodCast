//
//  UIViewController.swift
//  Podcast
//
//  Created by Jonathan Mora on 05/05/26.
//
import UIKit

extension UIViewController {
    func clearCollectionViewSelection(_ collectionView: UICollectionView, animated: Bool) {
        guard let selected = collectionView.indexPathsForSelectedItems,
              !selected.isEmpty else { return }
        
        guard let coordinator = transitionCoordinator else {
            selected.forEach { collectionView.deselectItem(at: $0, animated: animated) }
            return
        }
        
        coordinator.animate { _ in
            selected.forEach { collectionView.deselectItem(at: $0, animated: true) }
        } completion: { context in
            if context.isCancelled {
                selected.forEach {
                    collectionView.selectItem(at: $0, animated: false, scrollPosition: [])
                }
            }
        }
    }
}

extension UIViewController {
    /// Shows the screen's `title` on the left of the navigation bar, bold
    /// serif, instead of centered (the tabs' first screens: Home, Library, Search).
    /// Call after setting `title`.
    func showTitleOnLeading() {
        let label = UILabel()
        label.text = title
        // Editorial: serif (New York), like the podcast page.
        let base = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.font = base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: 28) } ?? base
        label.textColor = .label
        label.accessibilityTraits = .header
        label.sizeToFit()

        let item = UIBarButtonItem(customView: label)
        // A plain title, not a button: no glass capsule behind it.
        item.hidesSharedBackground = true
        navigationItem.leftBarButtonItem = item
        // An empty title view hides the centered copy of the title (the
        // `title` itself stays, for VoiceOver and the back button).
        navigationItem.titleView = UIView()
    }
}

extension UIViewController {
    /// Adds a child controller whose view fills this one's edge to edge.
    func embedFullScreen(_ child: UIViewController) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        child.view.backgroundColor = .clear
        view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        child.didMove(toParent: self)
    }
}

extension UIViewController {
    /// No title in the navigation bar, just the back arrow: the screen's
    /// content says what it is, and the bar stays slim. `title` stays set
    /// (VoiceOver, and the back button's long-press menu).
    func hideNavigationTitle() {
        navigationItem.titleView = UIView()
    }

    /// A clear navigation bar with no title: only the back button, over
    /// the page (the page's own header shows what it is). `title` still
    /// names the screen in the back button's menu.
    func useClearNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
        navigationItem.largeTitleDisplayMode = .never
        hideNavigationTitle()
    }
}
