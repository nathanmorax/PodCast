//
//  HostingCellBackground.swift
//  Podcast
//
//  Created by Jonathan Mora on 30/04/26.
//
import SwiftUI
import UIKit

enum HostingCellBackground {
    case none
    case card
    case custom(AnyView)
    
    /// Factory ergonómico para no escribir AnyView(...) en el call site.
    static func custom<V: View>(@ViewBuilder _ view: () -> V) -> HostingCellBackground {
        .custom(AnyView(view()))
    }
}

extension UICollectionView {
    /// - Parameter margins: space around the SwiftUI content. Nil keeps the
    ///   system cell margins (~11 pt top/bottom); fixed-height rows pass 0 so
    ///   their content gets the whole height and can't spill out.
    static func hostingRegistration<Item, Content: View>(
        backgroundStyle: HostingCellBackground = .card,
        margins: CGFloat? = nil,
        @ViewBuilder content: @escaping @MainActor (Item) -> Content
    ) -> UICollectionView.CellRegistration<UICollectionViewCell, Item> {
        .init { cell, _, item in
            var base = UIHostingConfiguration { content(item) }
            if let margins {
                base = base.margins(.all, margins)
                // Nothing from this row may draw over the next one.
                cell.clipsToBounds = true
            }
            
            switch backgroundStyle {
            case .none:
                cell.contentConfiguration = base
            case .card:
                cell.contentConfiguration = base.background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                }
            case .custom(let view):
                cell.contentConfiguration = base.background { view }
            }
        }
    }
    
    static func hostingListRegistration<Item, Content: View>(
        backgroundStyle: HostingCellBackground = .none,
        @ViewBuilder content: @escaping @MainActor (Item) -> Content
    ) -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        .init { cell, _, item in
            let base = UIHostingConfiguration { content(item) }
            switch backgroundStyle {
            case .none:
                cell.contentConfiguration = base
            case .card:
                cell.contentConfiguration = base.background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                }
            case .custom(let view):
                cell.contentConfiguration = base.background { view }
            }
        }
    }
}

extension UICollectionView {
    static func hostingSupplementaryRegistration<Item, Content: View>(
        elementKind: String,
        background: HostingCellBackground = .none,
        itemProvider: @escaping () -> Item?,
        @ViewBuilder content: @escaping @MainActor (Item) -> Content
    ) -> UICollectionView.SupplementaryRegistration<UICollectionViewCell> {
        UICollectionView.SupplementaryRegistration(elementKind: elementKind) { supplementaryView, _, _ in
            guard let item = itemProvider() else { return }
            
            let base = UIHostingConfiguration { content(item) }
            switch background {
            case .none:
                supplementaryView.contentConfiguration = base
            case .card:
                supplementaryView.contentConfiguration = base.background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                }
            case .custom(let view):
                supplementaryView.contentConfiguration = base.background { view }
            }
        }
    }
}
