//
//  CollectionsMenu.swift
//  Podcast
//

import SwiftUI

/// The collections menu: big stacked pills (name left, icon right) over a
/// dimmed screen, right above the search button. The pill under the finger
/// lights up in lavender; tap or release on one to open it; tap outside to
/// close.
struct CollectionsMenu: View {

    let navigator: AppNavigator
    /// Space taken by the bottom bar (the menu sits right above it).
    let bottomInset: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { navigator.closeCollectionsMenu() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Close")

            VStack(spacing: 10) {
                ForEach(LibraryCollection.allCases) { collection in
                    CollectionPill(
                        collection: collection,
                        isHighlighted: navigator.highlightedCollection == collection
                    ) {
                        navigator.open(collection)
                    }
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .global)
                    } action: { frame in
                        navigator.collectionFrames[collection] = frame
                    }
                }
            }
            .frame(width: 260)
            .padding(.trailing, 16)
            .padding(.bottom, bottomInset)
        }
        .sensoryFeedback(.selection, trigger: navigator.highlightedCollection)
    }
}

private struct CollectionPill: View {

    let collection: LibraryCollection
    let isHighlighted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(collection.title)
                    .font(AppFont.headline)
                Spacer(minLength: 0)
                Image(systemName: collection.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(isHighlighted ? AppColor.Text.onPastel : AppColor.Text.primary)
            .padding(.horizontal, 22)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isHighlighted ? AppColor.Accent.soft : AppColor.Surface.raised)
            )
            .scaleEffect(isHighlighted ? 1.03 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.selection, value: isHighlighted)
    }
}
