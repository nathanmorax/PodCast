//
//  ArtworkTint.swift
//  Podcast
//

import SwiftUI

/// The color a podcast's page is painted with, taken from its artwork
/// (like Apple Podcasts). Only the three components: Sendable, so it can be
/// computed off the main actor.
struct ArtworkTint: Sendable, Equatable {

    let red: Double
    let green: Double
    let blue: Double

    var color: Color { Color(red: red, green: green, blue: blue) }

    /// The gradient's bottom: a little deeper, toward the text's opposite,
    /// so the text keeps (or gains) contrast as the color goes down.
    var deeper: Color {
        let target: Double = prefersLightText ? 0 : 1
        let amount = 0.16
        return Color(
            red: red + (target - red) * amount,
            green: green + (target - green) * amount,
            blue: blue + (target - blue) * amount
        )
    }

    /// White or ink on this color, whichever contrasts more (WCAG ratio).
    var prefersLightText: Bool {
        let onWhite = 1.05 / (luminance + 0.05)
        let onInk = (luminance + 0.05) / (Self.inkLuminance + 0.05)
        return onWhite >= onInk
    }

    var text: Color { prefersLightText ? .white : AppColor.Text.onPastel }
    var secondaryText: Color { text.opacity(0.75) }

    /// Relative luminance (WCAG 2.1).
    var luminance: Double {
        func linear(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// #111111, the app's ink.
    private static let inkLuminance = 0.0056
}

extension ArtworkTint {

    /// Keeps the page readable when the artwork is almost white or almost
    /// black: never paper-white (the page would have no header) nor pitch
    /// black (the shadow under the cover would vanish).
    func softened() -> ArtworkTint {
        let maxComponent = max(red, green, blue)
        let minComponent = min(red, green, blue)
        if minComponent > 0.9 {
            let scale = 0.9 / minComponent
            return ArtworkTint(red: red * scale, green: green * scale, blue: blue * scale)
        }
        if maxComponent < 0.08 {
            let lift = 0.08 - maxComponent
            return ArtworkTint(red: red + lift, green: green + lift, blue: blue + lift)
        }
        return self
    }
}
