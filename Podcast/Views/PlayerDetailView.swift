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
   
   @IBOutlet weak var episodeImageView: UIImageView! {
      didSet {
         episodeImageView.layer.cornerRadius =  5
         episodeImageView.clipsToBounds = true
         episodeImageView.transform = shrunkenTransform
      }
   }
   
   var episode: Episode? {
      didSet {
         titleEpisodeLabel.text = episode?.title
         authorLabel.text = episode?.author
         
         playEpisode()
         
         guard let url = URL(string: episode?.imageUrl ?? "") else { return }
         episodeImageView.sd_setImage(with: url)
      }
   }
   
   let player: AVPlayer = {
      let avPlayer = AVPlayer()
      avPlayer.automaticallyWaitsToMinimizeStalling = false
      return avPlayer
   }()
   
   fileprivate func observerPlayerCurrentTime() {
      let interval = CMTimeMake(value: 1, timescale: 2)
      player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self](time) in
         self?.currentTimeLabel.text = time.toDisplayString()
         
         let duration = self?.player.currentItem?.duration
         self?.durationLabel.text = duration?.toDisplayString()
         
         self?.updateCurrentTimeSlider()

      }
   }
   
   override func awakeFromNib() {
      super.awakeFromNib()
      addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
      observerPlayerCurrentTime()
      
      let time = CMTimeMake(value: 1, timescale: 3)
      let times = [NSValue(time: time)]
      player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
         print("Episode started playing")
         self?.enlargeEpisodeImageView()
         
      }
   }
   static func initFromNib() -> PlayerDetailView {
      return Bundle.main.loadNibNamed("PlayerDetailView", owner: self, options: nil)?.first as! PlayerDetailView
   }
   
   fileprivate func updateCurrentTimeSlider() {
      let currentTimeSeconds = CMTimeGetSeconds(player.currentTime())
      let durationSeconds = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime(value: 1, timescale: 1))
      let percentage = currentTimeSeconds / durationSeconds
      
      self.currentTimeSlider.value = Float(percentage)
      
   }
   
   fileprivate func playEpisode() {
      guard let url = URL(string: episode?.streamUrl ?? "") else { return }
      let playerItem = AVPlayerItem(url: url)
      player.replaceCurrentItem(with: playerItem)
      player.play()
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
   fileprivate func seekToCurrentTime(delta: Int64) {
      
      let fifteenSeconds = CMTimeMake(value: delta, timescale: 1)
      let seekTime = CMTimeAdd(player.currentTime(), fifteenSeconds)
      player.seek(to: seekTime)
      
   }
   // MARK: - IBActions

   @IBAction func handleDismiss(_ sender: Any) {
      //self.removeFromSuperview()
      print("Dismisss")
      let mainTabController = UIApplication.shared.keyWindow?.rootViewController as? MainTabController
      mainTabController?.minimizePlayerDetail()
   }
   @IBAction func handleCurrentTimeSliderChange(_ sender: Any) {
      
      let percentage = currentTimeSlider.value
      guard let duration = player.currentItem?.duration else { return }
      let durationInSeconds = CMTimeGetSeconds(duration)
      let seekTimeInSeconds = Float64(percentage) * durationInSeconds
      let seekTime = CMTimeMakeWithSeconds(seekTimeInSeconds, preferredTimescale: Int32(NSEC_PER_SEC))
      player.seek(to: seekTime)
      
   }
   
   @IBAction func handleRewind(_ sender: Any) {
      seekToCurrentTime(delta: -15)
   }
   @IBAction func handleFastForward(_ sender: Any) {
      seekToCurrentTime(delta: 15)
   }
   @IBAction func handleVolumeChange(_ sender: UISlider) {
      player.volume = sender.value
   }
   @objc func handlePlayPause() {
      if player.timeControlStatus == .paused {
         player.play()
         playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)

         enlargeEpisodeImageView()
      } else {
         player.pause()
         playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
         shrinkEpisodeImageView()
      }
   }
   
}
