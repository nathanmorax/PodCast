//
//  View+GlassCapsule.swift
//  Podcast
//

import SwiftUI

extension View {
    /// Liquid Glass capsule shared by every piece of the bar (a circle on
    /// square frames), all with the same tone. The glass carries a light wash
    /// of the raised surface (white / dark gray in dark mode) so its text and
    /// icons stay readable over colorful content, while what's behind still
    /// shows through.
    func glassCapsule() -> some View {
        glassEffect(.regular.tint(AppColor.Surface.raised.opacity(0.4)), in: Capsule())
    }
}
