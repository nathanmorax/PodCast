//
//  BottomBar.swift
//  Podcast
//

import SwiftUI

/// The app's bottom bar:
/// - At rest: the mini player on top; below it the [Inicio | Biblioteca]
///   capsule next to the search field.
/// - Swiping sideways on the tabs capsule switches tab (the buttons still work;
///   swiping on the screen itself is handled by MainContainerController).
/// - Scrolling down: everything folds into one row with the current tab's icon,
///   the mini player and a search circle. Scrolling up brings it back.
/// - In Search, the field is the real search field. While typing it's the only
///   thing left (plus ✕), right above the keyboard.
struct BottomBar: View {

    @Environment(\.playerManager) private var manager
    let navigator: AppNavigator

    @Namespace private var namespace
    @FocusState private var isFieldFocused: Bool
    /// How far the finger has moved sideways on the tabs capsule.
    @State private var tabDrag: CGFloat = 0

    enum Metrics {
        static let miniPlayerHeight: CGFloat = 56
        static let rowHeight: CGFloat = 62
        static let compactHeight: CGFloat = 52
        static let spacing: CGFloat = 10
        /// A swipe has to (be thrown) this far to switch tab.
        static let swipeDistance: CGFloat = 60
    }

    /// Height of the bar at rest. RootView reserves it so lists end above it.
    static func restingHeight(isPlaying: Bool) -> CGFloat {
        isPlaying
            ? Metrics.miniPlayerHeight + Metrics.spacing + Metrics.rowHeight
            : Metrics.rowHeight
    }

    private var isCompact: Bool {
        navigator.isBarCompact && manager.currentEpisode != nil && !navigator.isSearching
    }

    private var showsMiniPlayerRow: Bool {
        manager.currentEpisode != nil && !isCompact && !navigator.isSearching
    }

    private static let spring = Animation.spring(response: 0.38, dampingFraction: 0.86)

    // The search field always sits at the same place in this structure, so it
    // keeps its identity (and the keyboard) while the rest of the bar changes.
    var body: some View {
        VStack(spacing: Metrics.spacing) {
            if showsMiniPlayerRow, let episode = manager.currentEpisode {
                MiniPlayerCapsule(episode: episode, showsSubtitle: true)
                    .frame(height: Metrics.miniPlayerHeight)
                    .matchedGeometryEffect(id: "player", in: namespace)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: Metrics.spacing) {
                if isCompact, let episode = manager.currentEpisode {
                    compactTabButton
                        .matchedGeometryEffect(id: "tabs", in: namespace)
                    MiniPlayerCapsule(episode: episode, showsSubtitle: false)
                        .frame(height: Metrics.compactHeight)
                        .matchedGeometryEffect(id: "player", in: namespace)
                } else if !navigator.isSearching {
                    tabsCapsule
                        .matchedGeometryEffect(id: "tabs", in: namespace)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                searchElement
                    .matchedGeometryEffect(id: "search", in: namespace)

                if navigator.isSearching {
                    cancelButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: isCompact ? Metrics.compactHeight : Metrics.rowHeight)
        }
        .animation(Self.spring, value: isCompact)
        .animation(Self.spring, value: navigator.isSearching)
        .animation(Self.spring, value: manager.currentEpisode?.streamUrl)
        .sensoryFeedback(.selection, trigger: navigator.selectedTab)
        // Keep the keyboard and the navigator in sync, both ways.
        .onChange(of: isFieldFocused) { _, focused in
            if navigator.isSearching != focused { navigator.isSearching = focused }
        }
        .onChange(of: navigator.isSearching) { _, searching in
            if isFieldFocused != searching { isFieldFocused = searching }
        }
    }

    // MARK: - Tabs

    private var tabsCapsule: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .offset(x: Self.rubberBand(tabDrag))
        .padding(.horizontal, 6)
        .frame(height: Metrics.rowHeight)
        .glassCapsule()
        .contentShape(Capsule())
        .highPriorityGesture(tabSwipe)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: navigator.selectedTab)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        // While Search is on screen no tab is highlighted: the search field is.
        let isSelected = !navigator.isShowingSearch && navigator.selectedTab == tab
        return Button {
            navigator.select(tab)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? tab.selectedSystemImage : tab.systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .frame(height: 24)
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? AppColor.lavenderInk : .black.opacity(0.6))
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background {
                if isSelected {
                    Capsule()
                        .fill(AppColor.lavender.opacity(0.3))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Sideways swipe on the tabs: the capsule follows the finger a little
    /// (live feedback) and a long or quick enough swipe switches tab.
    private var tabSwipe: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                tabDrag = value.translation.width
            }
            .onEnded { value in
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                let thrown = value.predictedEndTranslation.width
                if isHorizontal, abs(thrown) > Metrics.swipeDistance {
                    // Finger to the left → the tab on the right.
                    navigator.swipeTab(towardNext: thrown < 0)
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    tabDrag = 0
                }
            }
    }

    /// Follows the finger but resists, up to 18 pt either way.
    private static func rubberBand(_ x: CGFloat) -> CGFloat {
        CGFloat(18 * tanh(Double(x) / 60))
    }

    // MARK: - Search

    @ViewBuilder
    private var searchElement: some View {
        if isCompact {
            searchCircle
        } else if navigator.isShowingSearch {
            searchTextField
        } else {
            searchButton
        }
    }

    /// Outside Search: looks like the field, opens Search with the keyboard up.
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
        .accessibilityLabel("Search podcasts")
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
    }

    private var cancelButton: some View {
        Button {
            navigator.cancelSearchEditing()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: Metrics.rowHeight, height: Metrics.rowHeight)
                .glassCapsule()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel search")
    }

    // MARK: - Folded (while scrolling down)

    private var compactTabButton: some View {
        Button {
            navigator.expandBar()
        } label: {
            Image(systemName: navigator.isShowingSearch
                  ? navigator.selectedTab.systemImage
                  : navigator.selectedTab.selectedSystemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(navigator.isShowingSearch ? Color.black.opacity(0.6) : AppColor.lavenderInk)
                .frame(width: Metrics.compactHeight, height: Metrics.compactHeight)
                .glassCapsule()
        }
        .buttonStyle(.plain)
        .highPriorityGesture(tabSwipe)
        .accessibilityLabel(navigator.isShowingSearch
                            ? navigator.selectedTab.title
                            : String(localized: "\(navigator.selectedTab.title), current tab"))
        .accessibilityHint("Shows all tabs")
    }

    private var searchCircle: some View {
        Button {
            navigator.showSearch()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(navigator.isShowingSearch ? AppColor.lavenderInk : .black)
                .frame(width: Metrics.compactHeight, height: Metrics.compactHeight)
                .background {
                    if navigator.isShowingSearch {
                        Circle().fill(AppColor.lavender.opacity(0.3))
                    }
                }
                .glassCapsule()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search")
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
