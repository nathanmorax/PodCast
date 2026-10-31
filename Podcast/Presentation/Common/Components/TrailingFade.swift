//
//  TrailingFade.swift
//  Podcast
//

import SwiftUI

extension View {
    /// For a horizontal ScrollView: its right edge fades out, so the last
    /// visible item dissolves (there's more to swipe to). Once scrolled to
    /// the end, the fade goes away and the last item shows whole.
    func trailingFade(width: CGFloat = 48) -> some View {
        modifier(TrailingFade(width: width))
    }
}

private struct TrailingFade: ViewModifier {

    let width: CGFloat

    /// Scrolled all the way (or nothing to scroll).
    @State private var isAtEnd = false

    func body(content: Content) -> some View {
        content
            .mask {
                HStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .black.opacity(isAtEnd ? 1 : 0)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: width)
                }
                .animation(AppAnimation.stateChange, value: isAtEnd)
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                let end = geometry.contentSize.width + geometry.contentInsets.leading + geometry.contentInsets.trailing
                return geometry.contentOffset.x + geometry.containerSize.width >= end - 1
            } action: { _, atEnd in
                isAtEnd = atEnd
            }
    }
}
