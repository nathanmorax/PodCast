//
//  StretchyHeaderLayout.swift
//  Podcast
//
//  Created by Nathan Mora on 19/03/26.
//
import UIKit

final class StretchyHeaderLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }),
              let collectionView else { return nil }
        
        let offsetY = collectionView.contentOffset.y
        
        guard offsetY < 0 else { return attributes }
        
        if let headerAttributes = attributes.first(where: {
            $0.representedElementKind == UICollectionView.elementKindSectionHeader &&
            $0.indexPath.section == 0
        }) {
            let deltaY = abs(offsetY)
            var frame = headerAttributes.frame
            frame.origin.y    = offsetY
            frame.size.height = frame.size.height + deltaY
            headerAttributes.frame  = frame
            headerAttributes.zIndex = 0
        }
        
        return attributes
    }
    
    /// Only re-layout while the list is pulled past the top (the header
    /// stretches) and once more when it settles back, or when the size
    /// changes. Returning `true` always re-laid out every visible cell on
    /// every scroll frame, which made rows shift while scrolling.
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView else { return true }
        let current = collectionView.bounds
        if newBounds.size != current.size { return true }
        return newBounds.minY < 0 || current.minY < 0
    }
}
