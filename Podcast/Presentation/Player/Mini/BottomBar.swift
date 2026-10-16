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
            .foregroundStyle(isSelected ? Color.barAccentInk : .black.opacity(0.6))
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
                    .foregroundStyle(Color.barAccentInk)
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

// MARK: - Mini player capsule

/// What's playing: artwork with its progress strip, title, play/pause.
/// Tapping the info opens the full player.
private struct MiniPlayerCapsule: View {

    @Environment(\.playerManager) private var manager
    let episode: Episode
    /// Author and remaining time; hidden when the bar is folded.
    let showsSubtitle: Bool

    var body: some View {
        HStack(spacing: 4) {
            Button {
                manager.expand()
            } label: {
                HStack(spacing: 10) {
                    artwork

                    VStack(alignment: .leading, spacing: 1) {
                        Text(episode.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                        if showsSubtitle {
                            Text(subtitle)
                                .font(.system(size: 11))
                                .monospacedDigit()
                                .foregroundStyle(.black.opacity(0.55))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Abre el reproductor")

            Button {
                manager.togglePlayPause()
            } label: {
                Image(systemName: manager.viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(manager.viewModel.isPlaying ? "Pausar" : "Reproducir")
        }
        .padding(.leading, 9)
        .padding(.trailing, 6)
        .frame(maxHeight: .infinity)
        .glassCapsule()
    }

    private var artwork: some View {
        Color.clear
            .frame(width: 38, height: 38)
            .overlay { PodcastImage(source: episode.imageUrl) }
            .overlay(alignment: .bottomLeading) {
                // Progress lives on the artwork's bottom edge.
                GeometryReader { geo in
                    Rectangle()
                        .fill(AppColor.lavender)
                        .frame(width: geo.size.width * CGFloat(manager.viewModel.progress), height: 3)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var subtitle: String {
        let remaining = manager.viewModel.remainingTimeText
        return remaining.isEmpty ? episode.author : "\(episode.author) · −\(remaining)"
    }
}

// MARK: - Styling

private extension View {
    /// Frosted capsule shared by every piece of the bar (a circle on square frames).
    func glassCapsule() -> some View {
        background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}

private extension Color {
    /// Dark lavender for the selected tab's icon and label (#4C40A0).
    static let barAccentInk = Color(red: 0.298, green: 0.251, blue: 0.627)
}

#Preview {
    ZStack(alignment: .bottom) {
        Color(white: 0.96).ignoresSafeArea()
        BottomBar(navigator: .shared)
            .padding(.horizontal, 16)
    }
    .environment(\.playerManager, .preview)
}
