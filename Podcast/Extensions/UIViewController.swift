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
