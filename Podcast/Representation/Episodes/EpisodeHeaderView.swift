//
//  EpisodeHeaderView.swift
//  Podcast
//
//  Created by Satori Tech 341 on 19/03/26.
//
import UIKit
import SwiftUI

final class EpisodeHeaderView: UICollectionReusableView {
    
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleToFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.cornerRadius
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private let artistLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textColor = UIColor.white.withAlphaComponent(0.4)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 3
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let genreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 3
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let trackCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 3
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var contentStackV: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            headerImageView, titleLabel, artistLabel, descriptionLabel
        ])
        stack.axis      = .vertical
        stack.spacing   = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var contentStackH: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            trackCountLabel, genreLabel
        ])
        stack.axis      = .horizontal
        stack.distribution = .equalSpacing
        stack.spacing   = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - State
    private var currentImageURL: String?
    static let idIdentifierEpisodeHeader = "identifierEpisodeHeaderView"
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Setup
    
    private func setupView() {
        clipsToBounds = true

        addSubview(backgroundImageView)
        addSubview(blurView)
        blurView.contentView.addSubview(contentStackV)
        blurView.contentView.addSubview(contentStackH)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackV.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 16),
            contentStackV.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -16),
            contentStackV.bottomAnchor.constraint(equalTo: contentStackH.bottomAnchor, constant: -16),
            
            contentStackH.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 12),
            contentStackH.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -12),
            contentStackH.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -16),

            headerImageView.heightAnchor.constraint(equalToConstant: 130),
            headerImageView.widthAnchor.constraint(equalToConstant: 130),
        ])
    }
    
    // MARK: - Configure
    
    func configure(with podcast: Podcast?) {
        titleLabel.text  = podcast?.trackName
        artistLabel.text = podcast?.artistName
        trackCountLabel.text = podcast?.trackCount.map { "\($0) episodes" }
        genreLabel.text = podcast?.primaryGenreName

        guard let urlString = podcast?.artworkUrl600,
              let url = URL(string: urlString) else { return }

        currentImageURL = urlString
        headerImageView.sd_setImage(with: url)

        backgroundImageView.sd_setImage(with: url) { [weak self] image, _, _, _ in
            guard let self, let image, self.currentImageURL == urlString else { return }
            self.adaptTextColors(to: image)
        }
    }
    
    // MARK: - Color Adaptation

    private func adaptTextColors(to image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let brightness = image.averageBrightness()
            let isDark = brightness < 0.5

            let primary   = isDark ? UIColor.white : UIColor.black
            let secondary = isDark
                ? UIColor.white.withAlphaComponent(0.6)
                : UIColor.black.withAlphaComponent(0.5)

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                UIView.animate(withDuration: 0.2) {
                    self.titleLabel.textColor       = primary
                    self.artistLabel.textColor      = secondary
                    self.trackCountLabel.textColor  = secondary
                    self.genreLabel.textColor       = secondary
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        headerImageView.image     = nil
        backgroundImageView.image = nil
        backgroundImageView.backgroundColor = nil
        titleLabel.textColor      = .label
        artistLabel.textColor     = .secondaryLabel
        currentImageURL           = nil
    }
}

struct HeaderViewUI: View {
    
    var podcast: Podcast
    
    var body: some View {
        VStack(spacing: 12) {
            
            PodcastImage(source: podcast.artworkUrl600)
                .frame(maxWidth: 130, maxHeight: 130)
            
            Text(podcast.trackName ?? "")
            Text(podcast.artistName ?? "")

            HStack {
                Text("\(podcast.trackCount ?? 0) episodios")
                Spacer()
                Text(podcast.primaryGenreName ?? "")
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HeaderViewUI(podcast: .mock)
        .padding()
}


