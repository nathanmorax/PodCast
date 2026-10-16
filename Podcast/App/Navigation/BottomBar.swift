//
//  BottomBar.swift
//  Podcast
//

import SwiftUI

/// The app's bottom bar:
/// - At rest: the mini player on top; below it the [Inicio | Biblioteca]
///   capsule next to a "Buscar podcasts" field.
/// - Scrolling down: everything folds into one row with the current tab's icon,
///   the mini player and a search circle. Scrolling up brings it back.
struct BottomBar: View {

    @Environment(\.playerManager) private var manager
    let navigator: AppNavigator

    @Namespace private var namespace

    enum Metrics {
        static let miniPlayerHeight: CGFloat = 56
        static let rowHeight: CGFloat = 62
        static let compactHeight: CGFloat = 52
        static let spacing: CGFloat = 10
    }

    /// Height of the bar at rest. RootView reserves it so lists end above it.
    static func restingHeight(isPlaying: Bool) -> CGFloat {
        isPlaying
            ? Metrics.miniPlayerHeight + Metrics.spacing + Metrics.rowHeight
            : Metrics.rowHeight
    }

    private var isCompact: Bool {
        navigator.isBarCompact && manager.currentEpisode != nil
    }

    var body: some View {
        Group {
            if isCompact, let episode = manager.currentEpisode {
                compactRow(episode)
            } else {
                restingLayout
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: isCompact)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: manager.currentEpisode?.streamUrl)
    }

    // MARK: - At rest

    private var restingLayout: some View {
        VStack(spacing: Metrics.spacing) {
            if let episode = manager.currentEpisode {
                MiniPlayerCapsule(episode: episode, showsSubtitle: true)
                    .frame(height: Metrics.miniPlayerHeight)
                    .matchedGeometryEffect(id: "player", in: namespace)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: Metrics.spacing) {
                tabsCapsule
                    .matchedGeometryEffect(id: "tabs", in: namespace)
                searchField
                    .matchedGeometryEffect(id: "search", in: namespace)
            }
            .frame(height: Metrics.rowHeight)
        }
    }

    private var tabsCapsule: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: Metrics.rowHeight)
        .glassCapsule()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: navigator.selectedTab)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = navigator.selectedTab == tab
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

    /// Looks like a field, but it's a button: the real field lives at the top
    /// of the Search screen, with the keyboard.
    private var searchField: some View {
        Button {
            navigator.showSearch()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                Text("Buscar podcasts")
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
        .accessibilityLabel("Buscar podcasts")
    }

    // MARK: - Folded (while scrolling down)

    private func compactRow(_ episode: Episode) -> some View {
        HStack(spacing: Metrics.spacing) {
            Button {
                navigator.expandBar()
            } label: {
                Image(systemName: navigator.selectedTab.selectedSystemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(AppColor.lavenderInk)
                    .frame(width: Metrics.compactHeight, height: Metrics.compactHeight)
                    .glassCapsule()
            }
            .buttonStyle(.plain)
            .matchedGeometryEffect(id: "tabs", in: namespace)
            .accessibilityLabel("\(navigator.selectedTab.title), pestaña actual")
            .accessibilityHint("Muestra todas las pestañas")

            MiniPlayerCapsule(episode: episode, showsSubtitle: false)
                .frame(height: Metrics.compactHeight)
                .matchedGeometryEffect(id: "player", in: namespace)

            Button {
                navigator.showSearch()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: Metrics.compactHeight, height: Metrics.compactHeight)
                    .glassCapsule()
            }
            .buttonStyle(.plain)
            .matchedGeometryEffect(id: "search", in: namespace)
            .accessibilityLabel("Buscar")
        }
        .frame(height: Metrics.compactHeight)
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
