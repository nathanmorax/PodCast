//
//  EpisodeCell.swift
//  Podcast
//
//  Created by Xcaret Mora on 16/11/23.
//

import UIKit
import SwiftUI

struct EpisodeCell: View {
    let viewModel: EpisodeActionViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.episode.pubDate, style: .date)
                    .foregroundStyle(AppColor.dustyBlue)
                    .font(.subheadline)

                Text(viewModel.episode.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)

                Text(viewModel.episode.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer()

                Button {
                    viewModel.playOrPause()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(viewModel.episode.durationDisplayText)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .trailing, spacing: 0) {
                PodcastImage(source: viewModel.episode.imageUrl)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                EpisodeContextMenuButton(viewModel: viewModel)
                    .frame(width: 36, height: 36)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            PerformanceLogger.rendering.event("EpisodeCellUI appeared", "title: \(viewModel.episode.title)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Context Menu Button

private struct EpisodeContextMenuButton: UIViewRepresentable {
    let viewModel: EpisodeActionViewModel

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        button.tintColor = .black
        button.showsMenuAsPrimaryAction = true  // ← abre el menú con tap, sin long press
        button.menu = context.coordinator.makeMenu()
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        context.coordinator.viewModel = viewModel
        uiView.menu = context.coordinator.makeMenu()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject {
        var viewModel: EpisodeActionViewModel

        init(viewModel: EpisodeActionViewModel) {
            self.viewModel = viewModel
        }

        func makeMenu() -> UIMenu {
            let download = UIAction(
                title: "Descargar",
                image: UIImage(systemName: "arrow.down.circle")
            ) { [weak self] _ in
                self?.viewModel.download()
            }

            let bookmarkTitle = viewModel.isBookmarked ? "Quitar guardado" : "Guardar"
            let bookmarkIcon  = viewModel.isBookmarked ? "bookmark.slash" : "tray.and.arrow.down"
            let bookmark = UIAction(
                title: bookmarkTitle,
                image: UIImage(systemName: bookmarkIcon)
            ) { [weak self] _ in
                self?.viewModel.toggleBookmark()
            }

            return UIMenu(children: [download, bookmark])
        }
    }
}
