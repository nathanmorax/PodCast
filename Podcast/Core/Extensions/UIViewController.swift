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
