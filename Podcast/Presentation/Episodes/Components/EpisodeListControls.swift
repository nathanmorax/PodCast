//
//  EpisodeListControls.swift
//  Podcast
//

import SwiftUI

/// "EPISODES", then All · Unplayed · Downloaded as chips (the chosen one
/// filled in ink) and the order as a ⇅ menu on the right. The chips scroll
/// sideways when they don't fit (longer words in Spanish, large text).
struct EpisodeListControls: View {

    let filter: EpisodeFilter
    let order: EpisodeOrder
    let onFilter: (EpisodeFilter) -> Void
    let onOrder: (EpisodeOrder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Episodes")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColor.Text.primary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(EpisodeFilter.allCases, id: \.self) { item in
                            chip(item)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
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
                .lineLimit(1)
                .fixedSize()
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
            Image(systemName: "arrow.up.arrow.down")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.Text.secondary)
                .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Order")
        .accessibilityValue(Text(order.title))
    }
}
