//
//  LibraryTabBar.swift
//  Podcast
//

import SwiftUI

/// NEW · SAVED · DOWNLOADS · HISTORY in small spaced capitals, a mustard
/// line sliding under the chosen one. Scrolls sideways if a large text
/// size makes them wider than the screen.
struct LibraryTabBar: View {

    @Binding var tab: LibraryTab

    @Namespace private var line

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach(LibraryTab.allCases) { item in
                    button(item)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    private func button(_ item: LibraryTab) -> some View {
        let isOn = tab == item
        return Button {
            withAnimation(AppAnimation.selection) { tab = item }
        } label: {
            Text(item.title)
                .font(.footnote.weight(.heavy))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(isOn ? AppColor.Text.primary : AppColor.Text.secondary)
                .lineLimit(1)
                .frame(minHeight: 44)
                .overlay(alignment: .bottom) {
                    if isOn {
                        Rectangle()
                            .fill(AppColor.Accent.soft)
                            .frame(height: 2)
                            .padding(.bottom, 8)
                            .matchedGeometryEffect(id: "line", in: line)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}
