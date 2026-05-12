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
    
    // MARK: - Hit Test

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Expanded: capture everything
        if miniPlayerView.isHidden || miniPlayerView.alpha == 0 {
            return super.hitTest(point, with: event)
        }
        
        // Collapsed: only capture touches inside the mini player
        let pointInMiniPlayer = miniPlayerView.convert(point, from: self)
        if miniPlayerView.bounds.contains(pointInMiniPlayer) {
            return super.hitTest(point, with: event)
        }
        
        // Otherwise let the touch pass through
        return nil
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize))
        miniPlayerView.addGestureRecognizer(tap)
        miniPlayerView.isUserInteractionEnabled = true
    }
    
    private func setupMiniPlayerGlass() {
        let blurEffect = UIBlurEffect(style: .light)
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
    
    func maximize() {
        miniPlayerView.isHidden = false
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut) {
            self.maximizedStackView.alpha = 1
            self.miniPlayerView.alpha = 0
            self.backgroundColor = .black
        }
    }
    
    
    func minimize() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut) {
            self.maximizedStackView.alpha = 0
            self.miniPlayerView.alpha = 1
            self.miniPlayerView.isHidden = false
            self.backgroundColor = .clear
        }
    }
    
    @IBOutlet weak var episodeImageView: UIImageView! {
        didSet {
            episodeImageView.layer.cornerRadius =  16
            episodeImageView.clipsToBounds = true
            episodeImageView.transform = shrunkenTransform
        }
    }
    
    @IBOutlet weak var miniPlayPauseButton: UIButton! {
        didSet {
                var config = miniPlayPauseButton.configuration ?? .plain()
                config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                miniPlayPauseButton.configuration = config
                
                miniPlayPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
            }
    }
    
    @IBOutlet weak var miniFastForwardButton: UIButton! {
        didSet {
               var config = miniFastForwardButton.configuration ?? .plain()
               config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
               miniFastForwardButton.configuration = config
               
               miniFastForwardButton.addTarget(self, action: #selector(handleFastForward(_:)), for: .touchUpInside)
           }
    }
    
    static func initFromNib() -> PlayerDetailView {
        return Bundle.main.loadNibNamed("PlayerDetailView", owner: self, options: nil)?.first as! PlayerDetailView
    }
    
    @objc func handleTapMaximize() {
        PlayerManager.shared.expand()
    }
    
    @objc private func handlePlayPause() {
        viewModel.togglePlayPause()
    }
    
    // MARK: - IBActions
    
    @IBAction func handleDismiss(_ sender: Any) {
        PlayerManager.shared.collapse()
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
