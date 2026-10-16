//
//  DownloadButton.swift
//  Podcast
//

import SwiftUI

struct DownloadButton: View {
    let episode: Episode
    // Not @State: the view doesn't own the manager, it just reads it.
    @Environment(\.downloadManager) private var downloadManager
    @State private var spinAngle: Double = 0

    private var state: DownloadState {
        downloadManager.state(for: episode)
    }

    var body: some View {
        Button {
            withAnimation { handleTap() }
        } label: {
            ZStack {
                ring
                icon
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .onChange(of: isActive) { _, active in
            if active {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    spinAngle = 360
                }
            } else {
                spinAngle = 0
            }
        }
    }

    // MARK: - Ring

    @ViewBuilder
    private var ring: some View {
        switch state {
        case .idle, .failed, .downloaded:
            EmptyView()
            
        case .waiting:
            Circle()
                .stroke(Color.black.opacity(0.4), lineWidth: 1)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .rotationEffect(.degrees(spinAngle))
                .onAppear {
                    withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                        spinAngle = 360
                    }
                }
            
        case .downloading(let progress):
//            Circle()
//                .stroke(Color.black.opacity(0.15), style: StrokeStyle(lineWidth: 3, dash: [4, 4]))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.black, style: StrokeStyle(lineWidth: 3, lineCap: .butt, dash: [4, 4]))
                .rotationEffect(.degrees(-90)) // fijo, solo para empezar desde arriba
            
        }
    }

    // MARK: - Icon

    @ViewBuilder
    private var icon: some View {
        let symbolName: String = {
            switch state {
            case .idle, .failed:    return "arrow.down.square.fill"
            case .waiting:          return "xmark"
            case .downloading:      return "xmark"
            case .downloaded:       return "arrow.down.square.fill"
            }
        }()

        Image(systemName: symbolName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(iconColor)
            .contentTransition(.symbolEffect(.replace))
            .animation(.easeInOut(duration: 0.25), value: symbolName)
    }

    // MARK: - Helpers

    private var iconColor: Color {
        switch state {
        case .idle, .failed:    return .black.opacity(0.2)
        case .waiting, .downloaded, .downloading: return .black
        }
    }

    private var isActive: Bool {
        switch state {
        case .downloading, .waiting: return true
        default:                     return false
        }
    }
    
    // MARK: - Actions

    private func handleTap() {
        switch state {
        case .idle, .failed:         downloadManager.download(episode)
        case .downloading, .waiting: downloadManager.cancelDownload(episode)
        case .downloaded:            downloadManager.deleteDownload(episode)
        }
    }
}
