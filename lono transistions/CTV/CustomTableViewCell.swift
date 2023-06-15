//
//  CustomTableViewCell.swift
//  lono transistions
//
//  Created by Priyam Mehta on 15/06/23.
//

import UIKit
import AVFoundation

class CustomTableViewCell: UITableViewCell {
    var player: AVPlayer?
    var player1: AVPlayer?
    
    var playerIsPlaying: Bool = false
    var player1IsPlaying: Bool = false
    
    @IBOutlet weak var view1: UIView!
    
    @IBOutlet weak var titleLabel1: UILabel!
    
    @IBOutlet weak var imgView: UIImageView!
    
    
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var view2: UIView!
    
    @IBOutlet weak var titleLabel2: UILabel!
    
    
    @IBOutlet weak var imgView2: UIImageView!
    
    
    
    @IBOutlet weak var playBtn2: UIButton!
    
    override func awakeFromNib() {
        setupCell()
    }
    
    //    let stackView: UIStackView = {
    //            let stackView = UIStackView()
    //            stackView.axis = .horizontal
    //            stackView.alignment = .fill
    //            stackView.distribution = .fillEqually
    //            return stackView
    //        }()
    //
    //        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    //            super.init(style: style, reuseIdentifier: reuseIdentifier)
    //            setupCell()
    //        }
    //
    //        required init?(coder aDecoder: NSCoder) {
    //            super.init(coder: aDecoder)
    //            setupCell()
    //        }
    
    private func setupCell() {
        playBtn.setTitle("", for: .normal)
        
        self.titleLabel1.text = "Sdjdd v"
        self.titleLabel2.text = "ddjvndsjvdf"
        
        setupVideoPlayer()
        
        //            stackView.translatesAutoresizingMaskIntoConstraints = false
        //            contentView.addSubview(stackView)
        //
        //            NSLayoutConstraint.activate([
        //                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
        //                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        //                stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
        //                stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        //            ])
    }
    
    //        func addCell(_ cell: UITableViewCell) {
    //            stackView.addArrangedSubview(cell)
    //        }
    
    @IBAction func playBtnClick(_ sender: Any) {
        
        if !playerIsPlaying {
            templatePlayBtnTapped(playingPlayer: 0)
        } else {
           templateStopBtnTapped(player: 0)
        }
        
        
    }
    
    
    
    
    
    
    @IBAction func playBtn2Click(_ sender: Any) {
        if !player1IsPlaying {
            templatePlayBtnTapped(playingPlayer: 1)
        } else {
            templateStopBtnTapped(player: 1)
        }
    }
    
    
    
    
    
    /// MARK: Video Player
    ///
    ///
    
    private func setupVideoPlayer() {
        // Player for first Template
        guard let path1 = Bundle.main.path(forResource: "Template-display-1", ofType: "mp4") else { return }
        
        self.player = AVPlayer(url: URL(fileURLWithPath: path1))
        let playerLayer = AVPlayerLayer(player: self.player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: self.view1.frame.size)
        self.view1.layer.insertSublayer(playerLayer, below: self.imgView.layer)
        player?.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: self.player?.currentItem)
        
        // Player for second Template
        guard let path2 = Bundle.main.path(forResource: "Template-display-2", ofType: "mp4") else { return }
        
        self.player1 = AVPlayer(url: URL(fileURLWithPath: path2))
        let playerLayer2 = AVPlayerLayer(player: self.player1)
        playerLayer2.videoGravity = .resizeAspectFill
        playerLayer2.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: self.view2.frame.size)
        self.view2.layer.insertSublayer(playerLayer2, below: self.imgView2.layer)
        player1?.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.player1ItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: self.player1?.currentItem)
        
        
        templateStopBtnTapped(player: 0)
        templateStopBtnTapped(player: 1)
        
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        self.player?.seek(to: CMTime.zero)
        self.player?.play()
    }
    
    @objc func player1ItemDidReachEnd(notification: NSNotification) {
        self.player1?.seek(to: CMTime.zero)
        self.player1?.play()
    }
    
    
    
    func templatePlayBtnTapped(playingPlayer: Int ) {
        
        switch (playingPlayer) {
        case 0:
            self.player?.play()
            self.playBtn.setImage(UIImage(named: "ic_pause"), for: .normal)
            self.imgView.isHidden = true
            self.playerIsPlaying = true
            //        self.viewModel.collageTemplateDataArray[0].isPlaying = true
            
            self.player1?.stop()
            self.playBtn2.setImage(UIImage(named: "ic_play"), for: .normal)
            self.imgView2.isHidden = false
            self.player1IsPlaying = false
            //        self.viewModel.collageTemplateDataArray[1].isPlaying = false
            
        case 1:
            self.player1?.play()
            self.playBtn2.setImage(UIImage(named: "ic_pause"), for: .normal)
            self.imgView2.isHidden = true
            self.player1IsPlaying = true
            //        self.viewModel.collageTemplateDataArray[0].isPlaying = true
            
            self.player?.stop()
            self.playBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            self.imgView.isHidden = false
            self.playerIsPlaying = false
            //        self.viewModel.collageTemplateDataArray[1].isPlaying = false
        default:
            self.player1?.stop()
            self.playBtn2.setImage(UIImage(named: "ic_play"), for: .normal)
            self.imgView2.isHidden = false
            self.player1IsPlaying = false
            //        self.viewModel.collageTemplateDataArray[1].isPlaying = false
            self.player?.stop()
            self.playBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            self.imgView.isHidden = false
            self.playerIsPlaying = false
            //        self.viewModel.collageTemplateDataArray[1].isPlaying = false
        }
    }
        
    
    func templateStopBtnTapped(player: Int) {
        
        switch (player) {
        case 0:
            self.player?.stop()
            self.playBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            self.imgView.isHidden = false
            self.playerIsPlaying = false
//            self.viewModel.collageTemplateDataArray[0].isPlaying = false
        case 1:
            self.player1?.stop()
            self.playBtn2.setImage(UIImage(named: "ic_play"), for: .normal)
            self.imgView2.isHidden = false
            self.player1IsPlaying = false
//            self.viewModel.collageTemplateDataArray[1].isPlaying = false
        default:
            self.player?.stop()
            self.playBtn.setImage(UIImage(named: "ic_play"), for: .normal)
            self.imgView.isHidden = false
            self.playerIsPlaying = false
//            self.viewModel.collageTemplateDataArray[0].isPlaying = false
            
            self.player1?.stop()
            self.playBtn2.setImage(UIImage(named: "ic_play"), for: .normal)
            self.imgView2.isHidden = false
            self.player1IsPlaying = false
//            self.viewModel.collageTemplateDataArray[1].isPlaying = false
        }
    }
    
}

//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//        btn.setTitle("dbfvfvbdf", for: .normal)
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
//
//}
