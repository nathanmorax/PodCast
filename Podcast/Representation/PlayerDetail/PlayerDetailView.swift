//
//  PlayerDetailView.swift
//  Podcast
//
//  Created by Xcaret Mora on 17/11/23.
//

import UIKit
import AVKit

class PlayerDetailView: UIView {
    
    private let viewModel = AVPlayerViewModel()
    fileprivate let shrunkenTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    
    @IBOutlet weak var titleEpisodeLabel: UILabel!
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
    @IBOutlet weak var miniTitleLabel: UILabel!
    @IBOutlet weak var miniEpisodeImageView: UIImageView!
    
    @IBOutlet weak var episodeImageView: UIImageView! {
        didSet {
            episodeImageView.layer.cornerRadius =  16
            episodeImageView.clipsToBounds = true
            episodeImageView.transform = shrunkenTransform
        }
    }
    
    @IBOutlet weak var miniPlayPauseButton: UIButton! {
        didSet {
            miniPlayPauseButton.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
            miniPlayPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var miniFastForwardButton: UIButton! {
        didSet {
            miniFastForwardButton.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
            miniFastForwardButton.addTarget(self, action: #selector(handleFastForward(_:)), for: .touchUpInside)
        }
    }
    var episode: Episode? {
        didSet {
            updateUI(with: episode)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupMiniPlayerGlass()
        setupViewModel()
        setupGestures()
        
    }
    
    
    static func initFromNib() -> PlayerDetailView {
        return Bundle.main.loadNibNamed("PlayerDetailView", owner: self, options: nil)?.first as! PlayerDetailView
    }
    
    private func setupUI() {
        setupMiniPlayerGlass()
        
        miniEpisodeImageView.layer.cornerRadius = 4
        miniEpisodeImageView.clipsToBounds = true
    }
    
    private func setupViewModel() {
        viewModel.onTimeUpdate = { [weak self] current, duration, percentage in
            self?.currentTimeLabel.text = current
            self?.durationLabel.text = duration
            self?.currentTimeSlider.value = percentage
        }
        
        viewModel.onPlayStateChange = { [weak self] isPlaying in
            self?.updatePlayPauseButton(isPlaying: isPlaying)
            isPlaying ? self?.enlargeEpisodeImageView() : self?.shrinkEpisodeImageView()
        }
        
        viewModel.onEpisodeStarted = { [weak self] in
            self?.enlargeEpisodeImageView()
        }
    }
    
    private func setupGestures() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize)))
    }
    
    private func setupMiniPlayerGlass() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        blurView.frame = miniPlayerView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 18
        blurView.clipsToBounds = true
        
        miniPlayerView.insertSubview(blurView, at: 0)
    }
    
    private func updateUI(with episode: Episode?) {
        titleEpisodeLabel.text = episode?.title
        miniTitleLabel.text = episode?.title
        authorLabel.text = episode?.author
        
        if let episode = episode {
            viewModel.playEpisode(episode)
        }
        
        guard let imageUrl = episode?.imageUrl,
              let url = URL(string: imageUrl) else { return }
        
        episodeImageView.sd_setImage(with: url)
        miniEpisodeImageView.sd_setImage(with: url)
    }
    
    private func updatePlayPauseButton(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
        miniPlayPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
        
        isPlaying ? enlargeEpisodeImageView() : shrinkEpisodeImageView()
    }
    
    
    // MARK: - Animations
    
    private func enlargeEpisodeImageView() {
        UIView.animate(
            withDuration: 0.75,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 1,
            options: .curveEaseOut
        ) {
            self.episodeImageView.transform = .identity
        }
    }
    
    private func shrinkEpisodeImageView() {
        UIView.animate(
            withDuration: 0.75,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 1,
            options: .curveEaseOut
        ) {
            self.episodeImageView.transform = self.shrunkenTransform
        }
    }
    
    @objc func handleTapMaximize() {
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabController
        mainTabBarController?.maximizePlayerDetails(episode: nil)
    }
    
    @objc private func handlePlayPause() {
        viewModel.togglePlayPause()
    }
    
    // MARK: - IBActions
    
    @IBAction func handleDismiss(_ sender: Any) {
        print("Dismiss")
        let mainTabController = UIApplication.shared.keyWindow?.rootViewController as? MainTabController
        mainTabController?.minimizePlayerDetails()
    }
    
    @IBAction func handleCurrentTimeSliderChange(_ sender: Any) {
        viewModel.seek(to: currentTimeSlider.value)
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
    
}
