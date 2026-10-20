//
//  SelfSizingListLayout.swift
//  Podcast
//

import UIKit

extension UICollectionViewCompositionalLayout {
    /// One full-width column whose rows take the height of their SwiftUI content.
    ///
    /// A fixed `sizeForItemAt` height doesn't clip `UIHostingConfiguration`
    /// content: anything taller is drawn over the next cell. With an
    /// `.estimated` height, UIKit asks each cell for its real size instead.
    static func selfSizingList(
        estimatedHeight: CGFloat = 120,
        spacing: CGFloat,
        contentInsets: NSDirectionalEdgeInsets
    ) -> UICollectionViewCompositionalLayout {
        let size = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(estimatedHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = contentInsets

        return UICollectionViewCompositionalLayout(section: section)
    }
}
