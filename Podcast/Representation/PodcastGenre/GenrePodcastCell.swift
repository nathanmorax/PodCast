//
//  GenrePodcastCell.swift
//  Podcast
//
//  Created by Satori Tech 341 on 25/02/26.
//
import UIKit

class GenrePodcastCell: UICollectionViewCell {
    
    static let identifier: String = "GenrePodcastCell"
    
    lazy var imageView = UIImageView(image: UIImage(named: "appicon"))
    let titleLabel = UILabel()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .lightGray
    }
    
    
    private func configure() {
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(data: Genre) {
        titleLabel.text = data.name
    }
}
