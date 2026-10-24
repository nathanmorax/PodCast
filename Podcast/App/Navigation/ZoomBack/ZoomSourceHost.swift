//
//  ZoomSourceHost.swift
//  Podcast
//

import SwiftUI
import UIKit

/// Any SwiftUI item (a card with text over its cover, a row) as a zoom
/// source: it's hosted in its own UIHostingController, so it has a real
/// UIView the system can hide and zoom into (`pushZooming(_:from:)`).
///
/// Put the item's whole Button (and its context menu) inside: touches land
/// on the inner hosting view, so a Button outside wouldn't get them.
///
/// The inner hosting controller inherits UIKit traits (light/dark, text
/// size), but not custom SwiftUI environment values (@Entry): pass what the
/// content needs as parameters.
struct ZoomSourceHost<Content: View>: UIViewControllerRepresentable {

    let id: ZoomID
    var cornerRadius: CGFloat = 0
    @ViewBuilder let content: () -> Content

    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let controller = UIHostingController(rootView: content())
        controller.view.backgroundColor = .clear
        // Its size is the content's; the outer layout already handles safe areas.
        controller.safeAreaRegions = []
        return controller
    }

    func updateUIViewController(_ controller: UIHostingController<Content>, context: Context) {
        controller.rootView = content()
        ZoomSources.shared.register(controller.view, id: id, cornerRadius: cornerRadius)
    }

    func sizeThatFits(_ proposal: ProposedViewSize,
                      uiViewController controller: UIHostingController<Content>,
                      context: Context) -> CGSize? {
        controller.sizeThatFits(in: CGSize(
            width: proposal.width ?? .greatestFiniteMagnitude,
            height: proposal.height ?? .greatestFiniteMagnitude
        ))
    }
}
