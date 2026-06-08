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
        HStack {
            WaveformIcon()

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.episode.pubDate, style: .date)
                    .foregroundStyle(AppColor.dustyBlue)
                    .font(.subheadline)
                Text(viewModel.episode.description)
                    .font(.caption)

                HStack {
                    Button {
                        viewModel.playOrPause()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text(viewModel.episode.durationDisplayText)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(Capsule().fill(Color.black.opacity(0.08)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    EpisodeContextMenuButton(viewModel: viewModel)
                        .frame(width: 36, height: 36)
                }
            }

            Spacer(minLength: 12)
        }
        .onAppear {
            PerformanceLogger.rendering.event("EpisodeCellUI appeared", "title: \(viewModel.episode.title)")
        }
        .padding(.horizontal, 8)
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
