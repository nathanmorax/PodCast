//
//  Color+UIColor.swift
//  Podcast
//

import SwiftUI
import UIKit

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}

extension ColorName {
    /// The asset as a UIColor for UIKit. `UIColor(named:)` keeps its light
    /// and dark versions and switches with the system appearance;
    /// converting a SwiftUI Color can freeze it to one of them.
    var uiColor: UIColor {
        UIColor(named: rawValue) ?? .systemBackground
    }
}
