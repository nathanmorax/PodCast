//
//  HostingHeaderView.swift
//  Podcast
//
//  Created by Jonathan Mora on 11/05/26.
//
import UIKit
import SwiftUI


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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }
}
