//
//  VideoCell.swift
//  Test
//
//  Created by Luca on 6/6/18.
//  Copyright © 2018 aaa. All rights reserved.
//

import UIKit
import AVFoundation

class VideoCell: UICollectionViewCell {
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnPause: UIButton!
    
    
    var player: AVPlayer?
    
    
    override func awakeFromNib() {
        self.btnPlay.isHidden = false
        self.btnPause.isHidden = true
    }
    
    func setPlayer(player: AVPlayer) {
        self.player = player
        let playerLayer = AVPlayerLayer(player: self.player!)
        playerLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        self.videoView.layer.addSublayer(playerLayer)
        
    }
    
    @IBAction func onPlay(_ sender: Any) {
        self.player!.play()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.finishedPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        self.btnPlay.isHidden = true
        self.btnPause.isHidden = false
    }
    
    @IBAction func onPause(_ sender: Any) {
        self.player!.pause()
        
        self.btnPlay.isHidden = false
        self.btnPause.isHidden = true
    }
    
    @objc func finishedPlaying(_ myNotification: NSNotification) {
        self.btnPlay.isHidden = false
        self.btnPause.isHidden = true
        
        self.player!.seek(to: kCMTimeZero)
    }
}
