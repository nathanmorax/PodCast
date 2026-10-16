//
//  View+GlassCapsule.swift
//  Podcast
//

import SwiftUI

extension View {
    /// Frosted capsule shared by every piece of the bar (a circle on square frames).
    func glassCapsule() -> some View {
        background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}
