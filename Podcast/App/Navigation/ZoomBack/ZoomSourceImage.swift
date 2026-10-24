//
//  ZoomSourceImage.swift
//  Podcast
//

import SwiftUI
import UIKit

/// A podcast's cover drawn by UIKit, so the zoom transition can grow the
/// podcast's page out of it and shrink the page back into it (ZoomSources).
/// Looks like PodcastImage: fills its frame, same cache, gray while loading.
struct ZoomSourceImage: UIViewRepresentable {

    let podcast: Podcast
    let cornerRadius: CGFloat

    func makeUIView(context: Context) -> ZoomSourceImageView {
        ZoomSourceImageView()
    }

    func updateUIView(_ view: ZoomSourceImageView, context: Context) {
        // Rows are reused for other podcasts: register and load again.
        ZoomSources.shared.register(view, podcastID: podcast.id, cornerRadius: cornerRadius)
        view.load(podcast.artworkUrl600)
    }

    static func dismantleUIView(_ view: ZoomSourceImageView, coordinator: ()) {
        view.cancel()
    }
}

/// No intrinsic size: SwiftUI's frame decides, like a resizable Image.
final class ZoomSourceImageView: UIView {

    private let imageView = UIImageView()
    private var source: String?
    private var task: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemFill
        clipsToBounds = true
        isUserInteractionEnabled = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    func load(_ newSource: String?) {
        guard newSource != source else { return }
        source = newSource
        cancel()
        imageView.image = nil

        guard let newSource, !newSource.isEmpty else { return }
        guard newSource.hasPrefix("http"), let url = URL(string: newSource) else {
            imageView.image = UIImage(named: newSource)   // previews
            return
        }
        if let cached = ImageMemoryCache.shared.image(for: url) {
            imageView.image = cached
            return
        }
        task = Task { [weak self] in
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
            guard let data = try? await URLSession.shared.data(for: request).0,
                  let image = await UIImage.decode(from: data),
                  !Task.isCancelled else { return }
            ImageMemoryCache.shared.insert(image, for: url)
            guard let self, self.source == newSource else { return }
            UIView.transition(with: self.imageView, duration: 0.2, options: .transitionCrossDissolve) {
                self.imageView.image = image
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
