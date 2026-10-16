//
//  BottomBar.swift
//  Podcast
//

import SwiftUI

/// The app's bottom bar. One row that changes with where you are:
/// - Inicio / Biblioteca: the mini player and, next to it, a search circle.
///   (Nothing playing: just the search field.) Tabs change by swiping the
///   screen sideways (MainContainerController), so they aren't listed here.
/// - Search: only the search field, plus a button to close Search (or ✕ to
///   cancel while typing). Swiping down on the field closes Search too.
/// - Scrolling down a list makes the row a little smaller.
/// - Swiping up on the search circle/field opens Search (no slide: the
///   keyboard coming up is the only motion).
struct BottomBar: View {

    @Environment(\.playerManager) private var manager
    let navigator: AppNavigator

    @Namespace private var namespace
    @FocusState private var isFieldFocused: Bool

    enum Metrics {
        static let rowHeight: CGFloat = 62
        static let compactHeight: CGFloat = 52
        static let spacing: CGFloat = 10
    }

    /// Height of the bar at rest (always one row). RootView reserves it so
    /// lists end above it.
    static func restingHeight(isPlaying: Bool) -> CGFloat {
        Metrics.rowHeight
    }

    private var inSearch: Bool {
        navigator.isShowingSearch || navigator.isSearching
    }

    private var showsMiniPlayer: Bool {
        manager.currentEpisode != nil && !inSearch
    }

    private var isCompact: Bool {
        navigator.isBarCompact && showsMiniPlayer
    }

    private var height: CGFloat {
        isCompact ? Metrics.compactHeight : Metrics.rowHeight
    }

    // The search element always sits at the same place in this structure, so
    // the field keeps its identity (and the keyboard) while the bar changes.
    var body: some View {
        HStack(spacing: Metrics.spacing) {
            if showsMiniPlayer, let episode = manager.currentEpisode {
                MiniPlayerCapsule(episode: episode, showsSubtitle: !isCompact)
                    .matchedGeometryEffect(id: "player", in: namespace)
                    .transition(.barLeadingItem)
            }

            searchElement
                .matchedGeometryEffect(id: "search", in: namespace)

            if inSearch {
                trailingSearchButton
                    .transition(.barAccessory)
            }
        }
        .frame(height: height)
        .animation(AppAnimation.bar, value: isCompact)
        .animation(AppAnimation.bar, value: inSearch)
        .animation(AppAnimation.bar, value: navigator.isSearching)
        .animation(AppAnimation.bar, value: manager.currentEpisode?.streamUrl)
        .sensoryFeedback(.selection, trigger: navigator.selectedTab)
        // Keep the keyboard and the navigator in sync, both ways.
        .onChange(of: isFieldFocused) { _, focused in
            if navigator.isSearching != focused { navigator.isSearching = focused }
        }
        .onChange(of: navigator.isSearching) { _, searching in
            if isFieldFocused != searching { isFieldFocused = searching }
        }
        // VoiceOver can't swipe the screen like a finger: offer the tabs here.
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: Text("Next tab")) { navigator.swipeTab(towardNext: true) }
        .accessibilityAction(named: Text("Previous tab")) { navigator.swipeTab(towardNext: false) }
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
                    .foregroundStyle(.black)
                Text(navigator.searchQuery.isEmpty ? String(localized: "Search podcasts") : navigator.searchQuery)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.black.opacity(0.5))
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
                .foregroundStyle(.black)
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
            .font(.system(size: 16))
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
                        .foregroundStyle(.black.opacity(0.3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear text")
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Capsule().fill(navigator.isSearching ? Color.white : AppColor.lavender.opacity(0.3))
        }
        .glassCapsule()
        .contentShape(Capsule())
        .onTapGesture { isFieldFocused = true }
        .gesture(swipeDownToClose)
    }

    /// ✕ while typing (clears and drops the keyboard); otherwise ⌄ closes Search.
    private var trailingSearchButton: some View {
        Button {
            if navigator.isSearching {
                navigator.cancelSearchEditing()
            } else {
                navigator.closeSearch()
            }
        } label: {
            Image(systemName: navigator.isSearching ? "xmark" : "chevron.down")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: Metrics.rowHeight, height: Metrics.rowHeight)
                .glassCapsule()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(navigator.isSearching ? Text("Cancel search") : Text("Close search"))
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
