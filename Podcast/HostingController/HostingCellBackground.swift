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
    static func hostingRegistration<Item, Content: View>(
        backgroundStyle: HostingCellBackground = .card,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> UICollectionView.CellRegistration<UICollectionViewCell, Item> {
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
    
    static func hostingListRegistration<Item, Content: View>(
        backgroundStyle: HostingCellBackground = .none,
        @ViewBuilder content: @escaping (Item) -> Content
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
        @ViewBuilder content: @escaping (Item) -> Content
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
