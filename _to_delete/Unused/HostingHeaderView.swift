//
//  HostingHeaderView.swift
//  Podcast
//
//  Created by Jonathan Mora on 11/05/26.
//
import UIKit
import SwiftUI


/// Hosts the SwiftUI header in the list.
///
/// A UIHostingController (not a hosting configuration) because it can ignore
/// the safe area (`safeAreaRegions = []`): the cover must start under the
/// status bar. It reports its own height to the layout.
final class HostingHeaderView: UICollectionReusableView {
    
    private var hostingController: UIHostingController<AnyView>?
    weak var parentViewController: UIViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func host<Content: View>(_ view: Content, parent: UIViewController) {
        if let existing = hostingController {
            existing.rootView = AnyView(view)
            return
        }
        
        let hosting = UIHostingController(rootView: AnyView(view))
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = .clear
        // The header starts under the status bar on purpose: don't let SwiftUI
        // push its content down by the safe area.
        hosting.safeAreaRegions = []
        
        parent.addChild(hosting)
        addSubview(hosting.view)
        
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        hosting.didMove(toParent: parent)
        self.hostingController = hosting
        self.parentViewController = parent
    }
    
    /// The layout asks how tall the header is for this width.
    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        guard let hostingController else { return layoutAttributes }
        let fitting = hostingController.sizeThatFits(
            in: CGSize(width: layoutAttributes.size.width, height: .greatestFiniteMagnitude)
        )
        let attributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
        attributes.size.height = ceil(fitting.height)
        return attributes
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }
}
