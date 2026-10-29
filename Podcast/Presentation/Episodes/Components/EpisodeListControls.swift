//
//  EpisodeListControls.swift
//  Podcast
//

import SwiftUI

/// "EPISODES", then All · Unplayed · Downloaded as chips (the chosen one
/// filled in ink) and the order as a menu on the right.
struct EpisodeListControls: View {

    let filter: EpisodeFilter
    let order: EpisodeOrder
    let onFilter: (EpisodeFilter) -> Void
    let onOrder: (EpisodeOrder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            EpisodeSectionTitle(title: "Episodes")

            HStack(spacing: 8) {
                ForEach(EpisodeFilter.allCases, id: \.self) { item in
                    chip(item)
                }
                Spacer(minLength: 0)
                orderMenu
            }
        }
        .foregroundStyle(AppColor.Text.primary)
        .sensoryFeedback(.selection, trigger: filter)
    }

    private func chip(_ item: EpisodeFilter) -> some View {
        let isOn = item == filter
        return Button {
            withAnimation(AppAnimation.selection) { onFilter(item) }
        } label: {
            Text(item.title)
                .font(.footnote.weight(.bold))
                .foregroundStyle(isOn ? AppColor.Text.inverse : AppColor.Text.primary)
                .padding(.horizontal, 14)
                .frame(minHeight: 34)
                .background {
                    if isOn {
                        Capsule().fill(AppColor.Text.primary)
                    } else {
                        Capsule().strokeBorder(AppColor.Text.primary.opacity(0.25), lineWidth: 1)
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var orderMenu: some View {
        Menu {
            Picker("Order", selection: Binding(get: { order }, set: { onOrder($0) })) {
                ForEach(EpisodeOrder.allCases, id: \.self) { item in
                    Text(item.title).tag(item)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(order == .newest ? "Newest" : "Oldest")
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppColor.Text.secondary)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Order")
        .accessibilityValue(Text(order.title))
    }
}
