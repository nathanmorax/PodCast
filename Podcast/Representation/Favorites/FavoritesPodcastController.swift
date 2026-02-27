//
//  FavoritesPodcastController.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//


//55 6245 3562

import UIKit

class FavoritesPodcastController: UIViewController {
    
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCollection()
    }
    
    func configureCollection() {
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(FavoritesPodcastCell.self, forCellWithReuseIdentifier: FavoritesPodcastCell.favoritesPodcastCellId)
        
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    
}


extension FavoritesPodcastController: UICollectionViewDataSource, UICollectionViewDelegate ,  UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavoritesPodcastCell.favoritesPodcastCellId, for: indexPath)
        cell.backgroundColor = .red
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (view.frame.width - 3 * 16) / 2
        
        return CGSize(width: width, height: width + 42)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
}


class FavoritesPodcastCell: UICollectionViewCell {
    
    static let favoritesPodcastCellId = "FavoritesPodcastCellId"
    
    let imageView = UIImageView(image: UIImage(named: "appicon"))

    let titlePodcastLabel = UILabel()
    let artistNameLabel = UILabel()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        
        titlePodcastLabel.text = "Title Podcast"
        titlePodcastLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        artistNameLabel.text = "Artist Name"
        artistNameLabel.font = UIFont.systemFont(ofSize: 14)
        artistNameLabel.textColor = .lightGray
        
        let stackView = UIStackView(arrangedSubviews: [
            imageView ,titlePodcastLabel, artistNameLabel
        ])
        
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
    }
}
