//
//  EpisodesController.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import UIKit
import FeedKit
import SDWebImage
import UIImageColors


final class StretchyHeaderLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }),
              let collectionView else { return nil }
        
        let offsetY = collectionView.contentOffset.y
        
        guard offsetY < 0 else { return attributes }
        
        if let headerAttributes = attributes.first(where: {
            $0.representedElementKind == UICollectionView.elementKindSectionHeader &&
            $0.indexPath.section == 0
        }) {
            let deltaY = abs(offsetY)
            var frame = headerAttributes.frame
            frame.origin.y    = offsetY
            frame.size.height = frame.size.height + deltaY
            headerAttributes.frame  = frame
            headerAttributes.zIndex = 0
        }
        
        return attributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

class EpisodesController: UIViewController {
    fileprivate let cellId = "cellId"
    private let headerView = EpisodeHeaderView()
    private let statusBarBackgroundView = UIView()
    
    
    private enum Layout {
        static let headerHeight: CGFloat   = 320
        static let cellHeight: CGFloat     = 120
        static let sectionInset            = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    var podcast: Podcast? {
        didSet {
            headerView.configure(with: podcast)
            loadEpisodes()
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = StretchyHeaderLayout()
        layout.minimumLineSpacing      = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset            = Layout.sectionInset
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.backgroundColor = .systemBackground
        cv.delegate   = self
        cv.dataSource = self
        return cv
    }()
    
    private lazy var viewModel: PodcastSearchViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return PodcastSearchViewModel(repository: repository)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupLayout()
        self.setupBindings()
        self.setupCollectionView()
        
        edgesForExtendedLayout = [.top]
        extendedLayoutIncludesOpaqueBars = true
        
        
    }
    
    private func setupLayout() {
            view.backgroundColor = .systemBackground
            view.addSubview(collectionView)
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: view.topAnchor),
                collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    
    
    private func setupBindings() {
        
        viewModel.onDataUpdated = { [weak self] in
            self?.collectionView.reloadData()
        }
        
        viewModel.onError = { error in
            print("Episodes error:", error)
        }
    }
    fileprivate func loadEpisodes() {
        
        guard let feedUrl =  podcast?.feedUrl else { return }
        viewModel.loadEpisodes(feedURL: feedUrl)
    }
    // MARK: - SetupWork
    
    private func setupCollectionView() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellId)
        
        collectionView.register(
            EpisodeHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: EpisodeHeaderView.idIdentifierEpisodeHeader
        )
    }
    
}

extension EpisodesController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.episodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellId,
            for: indexPath
        ) as? EpisodeCell else { return UICollectionViewCell() }
        
        cell.episode = viewModel.episodes[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: EpisodeHeaderView.idIdentifierEpisodeHeader,
                for: indexPath
              ) as? EpisodeHeaderView
                
        else { return UICollectionReusableView() }
        
        header.configure(with: podcast)
        return header
    }
}

extension EpisodesController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let episode = viewModel.episodes[indexPath.row]
        (UIApplication.shared.keyWindow?.rootViewController as? MainTabController)?
            .maximizePlayerDetails(episode: episode)
    }
}

extension EpisodesController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: Layout.cellHeight)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: Layout.headerHeight)
    }
}

final class EpisodeHeaderView: UICollectionReusableView {
    
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0.2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 8
//        iv.clipsToBounds = true
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 2
        return label
    }()
    
    private let artistLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 3
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            headerImageView, titleLabel, artistLabel, descriptionLabel
        ])
        stack.axis    = .vertical
        stack.spacing = 12
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
        addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            headerImageView.heightAnchor.constraint(equalToConstant: 120),
            headerImageView.widthAnchor.constraint(equalToConstant: 120),
        ])
    }
    
    // MARK: - Configure
    
    func configure(with podcast: Podcast?) {
        titleLabel.text  = podcast?.trackName
        artistLabel.text = podcast?.artistName
        
        guard let urlString = podcast?.artworkUrl600,
              let url = URL(string: urlString) else { return }
        
        currentImageURL = urlString
        
//        headerImageView.sd_setImage(with: url)
        headerImageView.sd_setImage(with: url) { [weak self] image, _, _, _ in
            guard let self,
                  let image,
                  self.currentImageURL == urlString else { return }
            
            image.getColors { [weak self] colors in
                guard let self, let colors else { return }
                self.backgroundImageView.backgroundColor = colors.background
                self.titleLabel.textColor  = colors.primary
                self.artistLabel.textColor = colors.secondary
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        headerImageView.image     = nil
        backgroundImageView.image = nil
        titleLabel.textColor      = .label
        artistLabel.textColor     = .secondaryLabel
        currentImageURL           = nil
    }
}
