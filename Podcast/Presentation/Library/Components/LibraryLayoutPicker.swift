//
//  LibraryLayoutPicker.swift
//  Podcast
//

import SwiftUI

/// List · 2 × 2 · 3 × 3, as a small segmented control (symbols only;
/// VoiceOver reads each one's name).
struct LibraryLayoutPicker: View {

    @Binding var layout: LibraryLayout

    var body: some View {
        Picker("Layout", selection: $layout) {
            ForEach(LibraryLayout.allCases) { option in
                Image(systemName: option.systemImage)
                    .accessibilityLabel(Text(option.title))
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .fixedSize()
    }
}
