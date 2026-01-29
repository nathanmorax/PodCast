//
//  PlayerDetailView.swift
//  Podcast
//
//  Created by Xcaret Mora on 17/11/23.
//

import UIKit
import AVKit

class PlayerDetailView: UIView {
    
    @IBOutlet weak var titleEpisodeLabel: UILabel!
    @IBOutlet weak var miniTitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var currentTimeSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton! {
        didSet {
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
            
        }
    }
    @IBOutlet weak var maximizedStackView: UIStackView!
    @IBOutlet weak var miniPlayerView: UIView!
    
    @IBOutlet weak var miniEpisodeImageView: UIImageView!
    @IBOutlet weak var episodeImageView: UIImageView! {
        didSet {
            episodeImageView.layer.cornerRadius =  5
            episodeImageView.clipsToBounds = true
            episodeImageView.transform = shrunkenTransform
        }
    }
    
    private let viewModel = AVPlayerViewModel()
    
    var episode: Episode? {
        didSet {
            bindEpisode()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize)))
        setupBindings()

    }
    
    func bindEpisode() {
        
        guard let episode else { return }
        
        titleEpisodeLabel.text = episode.title
        miniTitleLabel.text = episode.title
        authorLabel.text = episode.author
        
        if let url = URL(string: episode.imageUrl ?? "") {
            episodeImageView.sd_setImage(with: url)
            miniEpisodeImageView.sd_setImage(with: url)
        }
        
        viewModel.playEpisode(episode)
        
    }
    
    private func setupBindings() {
        viewModel.onTimeUpdate = { [weak self] current, duration, percentage in
            self?.currentTimeLabel.text = current
            self?.durationLabel.text = duration
            self?.currentTimeSlider.value = percentage
        }
        
        viewModel.onPlayStateChange = { [weak self] isPlaying in
            let image = UIImage(
                systemName: isPlaying ? "pause.fill" : "play.fill"
            )
            self?.playPauseButton.setImage(image, for: .normal)
            self?.miniPlayPauseButton.setImage(image, for: .normal)
            
            isPlaying
            ? self?.enlargeEpisodeImageView()
            : self?.shrinkEpisodeImageView()
        }
    }
    
    
    @objc func handleTapMaximize() {
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabController
        mainTabBarController?.maximizePlayerDetails(episode: nil)
    }
    
    static func initFromNib() -> PlayerDetailView {
        return Bundle.main.loadNibNamed("PlayerDetailView", owner: self, options: nil)?.first as! PlayerDetailView
    }
    
    fileprivate func enlargeEpisodeImageView() {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImageView.transform = .identity
        })
    }
    
    fileprivate let shrunkenTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    
    fileprivate func shrinkEpisodeImageView() {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImageView.transform = self.shrunkenTransform
        })
    }
    
    // MARK: - IBActions
    
    @IBAction func handleDismiss(_ sender: Any) {
        let mainTabController = UIApplication.shared.keyWindow?.rootViewController as? MainTabController
        mainTabController?.minimizePlayerDetails()
    }
    
    @IBAction func handleCurrentTimeSliderChange(_ sender: Any) {
        
        viewModel.seek(to: (sender as AnyObject).value)
        
    }
    
    @IBAction func handleRewind(_ sender: Any) {
        viewModel.seekBackward()
    }
    @IBAction func handleFastForward(_ sender: Any) {
        viewModel.seekForward()
    }
    @IBAction func handleVolumeChange(_ sender: UISlider) {
        viewModel.setVolume(sender.value)
    }
    @objc func handlePlayPause() {
        viewModel.togglePlayPause()
    }
    //
    @IBOutlet weak var miniPlayPauseButton: UIButton! {
        
        didSet {
            miniPlayPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var miniFastForwardButton: UIButton! {
        
        didSet {
            miniFastForwardButton.addTarget(self, action: #selector(handleFastForward(_:)), for: .touchUpInside)
        }
    }
    
}
