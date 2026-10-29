//
//  PageDots.swift
//  Podcast
//

import SwiftUI

/// ● ○ for pages you swipe sideways between: the current one is a short
/// ink capsule, the rest small faint dots. Tapping a dot goes to its page.
/// VoiceOver reads it as one adjustable control ("Player, 1 of 2").
struct PageDots<Page: Hashable>: View {

    let pages: [Page]
    @Binding var selection: Page
    /// Each page's name, for VoiceOver.
    let title: (Page) -> Text

    var body: some View {
        HStack(spacing: 0) {
            ForEach(pages, id: \.self) { page in
                let isOn = page == selection
                Button {
                    withAnimation(AppAnimation.playerTab) { selection = page }
                } label: {
                    Capsule()
                        .fill(AppColor.Text.primary.opacity(isOn ? 1 : 0.25))
                        .frame(width: isOn ? 18 : 6, height: 6)
                        .frame(width: 26, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .animation(AppAnimation.selection, value: selection)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title(selection))
        .accessibilityValue(Text("\(index + 1) of \(pages.count)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: go(by: 1)
            case .decrement: go(by: -1)
            @unknown default: break
            }
        }
    }

    private var index: Int { pages.firstIndex(of: selection) ?? 0 }

    private func go(by step: Int) {
        let next = index + step
        guard pages.indices.contains(next) else { return }
        selection = pages[next]
    }
}
