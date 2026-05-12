//
//  PlayerDetailView.swift
//  Podcast
//
//  Created by Xcaret Mora on 17/11/23.
//

import UIKit
import AVKit
import SwiftUI

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
        if miniPlayerView.isHidden || miniPlayerView.alpha == 0 {
            return super.hitTest(point, with: event)
        }
        
        let pointInMiniPlayer = miniPlayerView.convert(point, from: self)
        if miniPlayerView.bounds.contains(pointInMiniPlayer) {
            return super.hitTest(point, with: event)
        }
        
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


import SwiftUI

struct PlayerView: View {
    
    var episode: Episode
    @State private var isPlaying: Bool = false
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                backgroundImageEpisode
                
                playerPanel
            }
            .edgesIgnoringSafeArea(.top)
        }
    }
    
    // MARK: - Imagen superior del episodio
    private var backgroundImageEpisode: some View {
        PodcastImage(source: episode.imageUrl)
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .clipped()
    }
    
    // MARK: - Panel blanco inferior
    private var playerPanel: some View {
        VStack(spacing: 24) {
            descriptionEpisode
                .padding(.top, 32)
            
            waveForm
            
            buttonAction
            
            lyrics
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
    
    // MARK: - Título y autor
    private var descriptionEpisode: some View {
        VStack(spacing: 12) {
            Text(episode.title)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
            
            Text(episode.author ?? "Rebakah Shirley")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.gray)
        }
    }
    
    // MARK: - Waveform y tiempos
    private var waveForm: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            
            HStack {
                Text("17:30")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                
                Spacer()
                
                Text("43:20")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 48)
        }
    }
    
    // MARK: - Controles play/atrás/adelante
    private var buttonAction: some View {
        HStack(spacing: 48) {
            Button {
                // retroceder 15s
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.black)
            }
            
            Button {
                isPlaying.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.6, green: 0.45, blue: 0.95))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            
            Button {
                // adelantar 15s
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.black)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Texto inferior (lyrics / preview)
    private var lyrics: some View {
        VStack(spacing: 4) {
            Text("Why aren't more people investing")
                .font(.system(size: 15))
                .foregroundStyle(.gray.opacity(0.5))
            
            Text("in Africa's green energy?")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
            
            Text("Environmental researcher")
                .font(.system(size: 14))
                .foregroundStyle(.gray.opacity(0.6))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

#Preview {
    PlayerView(episode: .mock)
}


