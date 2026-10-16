//
//  ColorAssetTests.swift
//  PodcastTests
//

import Testing
import UIKit
@testable import Podcast

/// Every ColorName must exist in Assets.xcassets, otherwise Color(asset:)
/// silently draws nothing.
struct ColorAssetTests {

    @Test(arguments: ColorName.allCases)
    func colorSetExists(_ name: ColorName) {
        let bundle = Bundle(for: AppDelegate.self)
        #expect(
            UIColor(named: name.rawValue, in: bundle, compatibleWith: nil) != nil,
            "Falta el color \"\(name.rawValue)\" en Assets.xcassets"
        )
    }
}
