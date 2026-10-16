import os, re, json, shutil

PROJECT = os.environ.get('REORG_PROJECT') or os.path.expanduser('~/mnt/PodCast')
ROOT = os.path.join(PROJECT, 'Podcast')
TESTS = os.path.join(PROJECT, 'PodcastTests')
TRASH = os.path.join(PROJECT, '_to_delete')
COLORS = os.path.join(ROOT, 'Resources/Assets.xcassets/Color')

def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write(text)
    print('write', os.path.relpath(path, PROJECT))

# ------------------------------------------------------------ new color sets
# (r, g, b) — same value in light and dark, like the screens that use them
# (their text is hard-coded black, so a dark variant would break contrast).
NEW_COLORS = {
    'screenBackground': (245, 245, 245),  # #F5F5F5 — Inicio and Biblioteca
    'paper':            (246, 246, 244),  # #F6F6F4 — full player background
    'ink':              (18, 18, 20),     # #121214 — full player text
    'lavenderInk':      (76, 64, 160),    # #4C40A0 — selected tab, accents on light
}

def colorset(r, g, b):
    def entry(dark):
        e = {
            "color": {
                "color-space": "srgb",
                "components": {"alpha": "1.000", "blue": f"0x{b:02X}", "green": f"0x{g:02X}", "red": f"0x{r:02X}"},
            },
            "idiom": "universal",
        }
        if dark:
            e = {"appearances": [{"appearance": "luminosity", "value": "dark"}], **e}
        return e
    return json.dumps({"colors": [entry(False), entry(True)], "info": {"author": "xcode", "version": 1}}, indent=2) + '\n'

for name, rgb in NEW_COLORS.items():
    path = os.path.join(COLORS, f'{name}.colorset', 'Contents.json')
    assert not os.path.exists(path), name
    write(path, colorset(*rgb))

# The color set literally called "Color" (plain white) isn't used anywhere.
unused = os.path.join(COLORS, 'Color.colorset')
if os.path.exists(unused):
    dest = os.path.join(TRASH, 'Unused/Color.colorset')
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.move(unused, dest)
    print('move  Color.colorset -> _to_delete/Unused/')

asset_names = sorted(d[:-len('.colorset')] for d in os.listdir(COLORS) if d.endswith('.colorset'))
print('assets:', asset_names)

# ------------------------------------------------------------ ColorName.swift (the one file with the names)
write(os.path.join(ROOT, 'Core/DesignSystem/ColorName.swift'), '''//
//  ColorName.swift
//  Podcast
//

import SwiftUI

/// The name of every color set in Assets.xcassets/Color — the only place in
/// the code where those names are written.
///
/// To add a color: create the color set in Assets.xcassets/Color, add a case
/// here whose raw value is exactly the asset's name, and expose it in AppColor.
/// ColorAssetTests fails if a case has no matching asset.
enum ColorName: String, CaseIterable {

    // MARK: Palette (genre tiles, buttons, status)
    case limeGreen
    case dustyRose
    case coralRed
    case slateGray
    case warmOrange
    case paleYellow
    case dustyBlue
    case oliveGreen
    case burntOrange
    case charcoalBrown
    case lavender
    case background

    // MARK: Surfaces and ink
    case screenBackground
    case paper
    case ink
    case lavenderInk
}

extension Color {
    /// `Color(asset: .lavender)` instead of `Color("lavender")`: no typos.
    init(asset name: ColorName) {
        self.init(name.rawValue)
    }
}
''')

# ------------------------------------------------------------ AppColor.swift (was inside GenrePodcastCell.swift)
write(os.path.join(ROOT, 'Core/DesignSystem/AppColor.swift'), '''//
//  AppColor.swift
//  Podcast
//

import SwiftUI

/// The app's colors. Every one comes from Assets.xcassets (names in
/// ColorName); no hex or RGB values live in code.
enum AppColor {

    // MARK: - Raw palette

    static let limeGreen     = Color(asset: .limeGreen)
    static let dustyRose     = Color(asset: .dustyRose)
    static let coralRed      = Color(asset: .coralRed)
    static let slateGray     = Color(asset: .slateGray)
    static let warmOrange    = Color(asset: .warmOrange)
    static let paleYellow    = Color(asset: .paleYellow)
    static let dustyBlue     = Color(asset: .dustyBlue)
    static let oliveGreen    = Color(asset: .oliveGreen)
    static let burntOrange   = Color(asset: .burntOrange)
    static let charcoalBrown = Color(asset: .charcoalBrown)
    static let lavender      = Color(asset: .lavender)
    static let background    = Color(asset: .background)

    // MARK: - Surfaces and ink

    /// Light grey behind Inicio and Biblioteca.
    static let screenBackground = Color(asset: .screenBackground)
    /// Soft white of the full player.
    static let paper            = Color(asset: .paper)
    /// Near-black text of the full player.
    static let ink              = Color(asset: .ink)
    /// Dark lavender: selected tab, accents on light backgrounds.
    static let lavenderInk      = Color(asset: .lavenderInk)

    // MARK: - Semantic roles

    enum Brand {
        static let primary   = AppColor.background
        static let secondary = AppColor.paleYellow
    }

    enum Status {
        static let success  = AppColor.oliveGreen
        static let warning  = AppColor.burntOrange
        static let critical = AppColor.coralRed
        static let info     = AppColor.dustyBlue
    }

    enum Surface {
        static let primary   = AppColor.paleYellow
        static let secondary = AppColor.dustyRose
        static let elevated  = Color.white
    }

    enum Text {
        static let primary   = AppColor.charcoalBrown
        static let secondary = AppColor.slateGray
        static let inverse   = Color.white
    }

    /// Tile colors for genres.
    /// - slateGray is NOT here: it's the screen background, so those tiles looked empty.
    /// - charcoalBrown is NOT here: it's the text color, so labels on it were unreadable.
    static let palette: [Color] = [
        limeGreen, dustyRose, coralRed, warmOrange,
        paleYellow, dustyBlue, oliveGreen, burntOrange, lavender
    ]
}
''')

# Every case must have an asset and vice versa.
cases = re.findall(r'^\s+case (\w+)$', open(os.path.join(ROOT, 'Core/DesignSystem/ColorName.swift')).read(), re.M)
assert sorted(cases) == asset_names, (sorted(cases), asset_names)

# ------------------------------------------------------------ test
write(os.path.join(TESTS, 'ColorAssetTests.swift'), '''//
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
            "Falta el color \\"\\(name.rawValue)\\" en Assets.xcassets"
        )
    }
}
''')

# ------------------------------------------------------------ tidy headers
# Header comment must name the file it's in (e.g. "APIService.swift" in
# PodcastRemoteDataService.swift).
for base in (ROOT,):
    for dirpath, _, files in os.walk(base):
        for f in files:
            if not f.endswith('.swift'):
                continue
            path = os.path.join(dirpath, f)
            text = open(path).read()
            m = re.match(r'//\n//  (.+\.swift)\n', text)
            if m and m.group(1) != f:
                open(path, 'w').write(text.replace(f'//  {m.group(1)}\n', f'//  {f}\n', 1))
                print('header', os.path.relpath(path, ROOT), ':', m.group(1), '->', f)

# LibraryMenuItem only needs UUID.
p = os.path.join(ROOT, 'Presentation/Library/Models/LibraryMenuItem.swift')
t = open(p).read()
open(p, 'w').write(t.replace('import SwiftUI\n', 'import Foundation\n', 1))

# Old AppColor file name stays only for the cell.
print('done')
