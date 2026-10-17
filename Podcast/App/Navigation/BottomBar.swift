//
//  BottomBar.swift
//  Podcast
//

import SwiftUI

/// The app's bottom bar. One row that changes with where you are:
/// - Library (the main screen): the mini player and, next to it, a search
///   circle. (Nothing playing: just the search field.)
/// - Search: only the search field (with its clear button). ⌄ to close
///   Search is at the top right of the screen; swiping down on the field or
///   pulling the screen down closes it too.
/// - Screens opened from Search (a genre, a podcast): no bar.
/// - Swiping up on the search circle/field opens Search (no slide: the
///   keyboard coming up is the only motion).
struct BottomBar: View {

    @Environment(\.playerManager) private var manager
    let navigator: AppNavigator

    @Namespace private var namespace
    @FocusState private var isFieldFocused: Bool

    enum Metrics {
        /// Every piece of the row (mini player, search circle/field, ⌄) has
        /// this height, always: the bar never changes size.
        static let rowHeight: CGFloat = 62
        static let spacing: CGFloat = 10
    }

    static func layout(navigator: AppNavigator, isPlaying: Bool) -> BottomBarLayout {
        BottomBarLayout(
            isPlaying: isPlaying,
            inSearch: navigator.isShowingSearch || navigator.isSearching,
            isTyping: navigator.isSearching,
            isSearchDetail: navigator.hidesBottomBar
        )
    }

    /// Height of the bar at rest. RootView reserves it so lists end above it.
    static func restingHeight(_ layout: BottomBarLayout) -> CGFloat {
        layout.height(row: Metrics.rowHeight)
    }

    private var layout: BottomBarLayout {
        Self.layout(navigator: navigator, isPlaying: manager.currentEpisode != nil)
    }

    private var inSearch: Bool { layout.inSearch }

    private var showsMiniPlayer: Bool { layout.player == .inline }

    private var height: CGFloat { Metrics.rowHeight }

    // The search element always sits at the same place in this structure, so
    // the field keeps its identity (and the keyboard) while the bar changes.
    var body: some View {
        Group {
            if layout.showsSearchRow {
                mainRow
            }
        }
        .animation(AppAnimation.bar, value: layout)
        .animation(AppAnimation.bar, value: inSearch)
        .animation(AppAnimation.bar, value: navigator.isSearching)
        .animation(AppAnimation.bar, value: manager.currentEpisode?.streamUrl)
        // Keep the keyboard and the navigator in sync, both ways.
        .onChange(of: isFieldFocused) { _, focused in
            if navigator.isSearching != focused { navigator.isSearching = focused }
        }
        .onChange(of: navigator.isSearching) { _, searching in
            if isFieldFocused != searching { isFieldFocused = searching }
        }
        .accessibilityElement(children: .contain)
    }

    private var mainRow: some View {
        HStack(spacing: Metrics.spacing) {
            if showsMiniPlayer, let episode = manager.currentEpisode {
                MiniPlayerCapsule(episode: episode, showsSubtitle: true)
                    .matchedGeometryEffect(id: "player", in: namespace)
                    .transition(.barLeadingItem)
            }

            searchElement
                .matchedGeometryEffect(id: "search", in: namespace)

            // In Search the row is only the field: ⌄ (close) lives at the top
            // right of the screen, in its navigation bar.
        }
        .frame(height: height)
    }

    // MARK: - Search

    @ViewBuilder
    private var searchElement: some View {
        if navigator.isShowingSearch {
            searchTextField
        } else if showsMiniPlayer {
            searchCircle
        } else {
            searchButton
        }
    }

    /// Nothing playing, outside Search: a field-looking button, full width.
    private var searchButton: some View {
        Button {
            navigator.showSearch()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                Text(navigator.searchQuery.isEmpty ? String(localized: "Search podcasts") : navigator.searchQuery)
                    .font(AppFont.link)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassCapsule()
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .highPriorityGesture(swipeUpToSearch)
        .accessibilityLabel("Search podcasts")
    }

    /// Next to the mini player.
    private var searchCircle: some View {
        Button {
            navigator.showSearch()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)
                .frame(width: height, height: height)
                .glassCapsule()
        }
        .buttonStyle(.plain)
        .highPriorityGesture(swipeUpToSearch)
        .accessibilityLabel("Search")
    }

    /// In Search: the real field. Typing here filters the Search screen.
    private var searchTextField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.lavenderInk)
                .accessibilityHidden(true)

            TextField("Search podcasts", text: Binding(
                get: { navigator.searchQuery },
                set: { navigator.searchQuery = $0 }
            ))
            .font(AppFont.body)
            .foregroundStyle(AppColor.ink)
            .focused($isFieldFocused)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onSubmit { isFieldFocused = false }
            .onAppear {
                // Opened from the bar: the keyboard was already requested.
                if navigator.isSearching { isFieldFocused = true }
            }

            if !navigator.searchQuery.isEmpty {
                Button {
                    navigator.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(AppColor.Text.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear text")
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // No fill behind the field: only glass, so what's behind shows through.
        .glassCapsule()
        .contentShape(Capsule())
        .onTapGesture { isFieldFocused = true }
        .gesture(swipeDownToClose)
    }

    // MARK: - Gestures

    /// Swiping up on the search circle/field opens Search. A tap still works.
    private var swipeUpToSearch: some Gesture {
        DragGesture(minimumDistance: 14)
            .onEnded { value in
                let isVertical = abs(value.translation.height) > abs(value.translation.width)
                if isVertical, value.predictedEndTranslation.height < -60 {
                    navigator.showSearch()
                }
            }
    }

    /// Swiping down on the field closes Search (it drops back down).
    private var swipeDownToClose: some Gesture {
        DragGesture(minimumDistance: 14)
            .onEnded { value in
                let isVertical = abs(value.translation.height) > abs(value.translation.width)
                if isVertical, value.predictedEndTranslation.height > 60 {
                    navigator.closeSearch()
                }
            }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppColor.screenBackground.ignoresSafeArea()
        BottomBar(navigator: .shared)
            .padding(.horizontal, 16)
    }
    .environment(\.playerManager, .preview)
}
