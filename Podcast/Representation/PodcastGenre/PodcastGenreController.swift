//
//  GenrePodcastController.swift
//  Podcast
//
//  Created by Satori Tech 341 on 25/02/26.
//
import UIKit

class PodcastGenreController: UIViewController {
    
    
    private lazy var viewModel: GenresViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = GenresRepositoryImpl(remoteDataSource: remote)
        return GenresViewModel(repository: repository)
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad( )
        self.configure()
        self.loadData()
        
        viewModel.loadGenre()
    }
    
    func loadData() {
        
        viewModel.onDataUpdated = { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    func configure() {
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(GenrePodcastCell.self, forCellWithReuseIdentifier: GenrePodcastCell.identifier)
        
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension PodcastGenreController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.genre.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GenrePodcastCell.identifier, for: indexPath)
        if let cell = cell as? GenrePodcastCell {
            let genre = viewModel.genre[indexPath.item]
            cell.configure(data: genre)
        }
        return cell
    }
}

extension PodcastGenreController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = (collectionView.bounds.width - 3 * 16) / 2
        return CGSize(width: width, height: width - 28)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
}
