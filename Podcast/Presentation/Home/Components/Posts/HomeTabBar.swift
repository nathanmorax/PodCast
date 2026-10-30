//
//  HomeTabBar.swift
//  Podcast
//

import SwiftUI

/// For You · Following · Continue, the width split in three; the chosen
/// one in ink with a line under it, the others faint. A hairline runs
/// under the whole bar. Pinned under the shows while the feed scrolls.
struct HomeTabBar: View {

    @Binding var tab: HomeTab

    @Namespace private var line

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeTab.allCases) { item in
                button(item)
            }
        }
        .overlay(alignment: .bottom) { Divider() }
        .background(AppColor.screenBackground)
        .sensoryFeedback(.selection, trigger: tab)
    }

    private func button(_ item: HomeTab) -> some View {
        let isOn = tab == item
        return Button {
            withAnimation(AppAnimation.selection) { tab = item }
        } label: {
            Text(item.title)
                .font(.callout.weight(isOn ? .semibold : .regular))
                .foregroundStyle(isOn ? AppColor.Text.primary : AppColor.Text.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 46)
                .overlay(alignment: .bottom) {
                    if isOn {
                        Rectangle()
                            .fill(AppColor.Text.primary)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "line", in: line)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected, .isHeader] : [])
    }
}
