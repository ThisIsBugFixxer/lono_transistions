//
//  ViewController.swift
//  lono transistions
//
//  Created by Priyam Mehta on 20/02/23.
//

import UIKit
import AVFoundation
import AVKit
import PhotosUI

class ViewController: UIViewController, PHPickerViewControllerDelegate {
    
    var selectedImages: [UIImage] = []
    var vc = VideoCreatorGeneralised()
    var lastPath: String? = nil
    
    var pickerSelectionLimit = 10
    
    var fgBGRemoved = [Bool]()
    var fgFramesRemoved = [Int]()
    
    
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var btnview: UIButton!
    
    
    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var videoPlayer = AVPlayer()
//    var back = BackgroundRemoval()
    @IBOutlet weak var modelBtn: UIButton!
    
    let anim = AnimateImages()
    var counter = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        self.spinner.stopAnimating()
        
        
        imgView.image = UIImage(named: "img")
        anim.bgImage = imgView
        anim.fgImage = imgView
        counterLabel.text = "iteration is \(counter)"
        let templateGenerator = templateGenerator.shared
        
       let newTemplatesList = templateGenerator.JSONExtractorTesting(fileName: "jsontestFile")
        let template1 = newTemplatesList.first?.Templates.first!
        
        self.counterLabel.text = "Data is \(template1)"
        
        
        
        /// Mark: Modifying the params
        ///
        
        pickerSelectionLimit = template1!.n_images
        
        var bgPhotosArray = [UIImage]()
        var fgPhotosArray = [UIImage]()
        let transistion = [Transistions.leftToRight, Transistions.DiagonalTBLR,Transistions.bottomToTop,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight]
        
//        print("=== initialisnig the model")
//        back.removeBackground(image: UIImage(named: "1.JPG")!, maskOnly: true)
//        print("=== done")
//
//        for i in 1..<11 {
//            // setting up the bg images
//            bgPhotosArray.append(UIImage(named: "\(i).JPG")!) //name of the images: 1.JPG, 2.JPG, 3.JPG, 4.JPG, 5.JPG
//            print(bgPhotosArray[i-1])
//        }
//
//        for image in 11..<21 { // setting up the fg images
//            fgPhotosArray.append(back.removeBackground(image: UIImage(named: "\(image).JPG")!)) // next 5 images
////            transistion.append(.leftToRight)
//
//        }
        print("=== \(fgPhotosArray)")
        
        
//        self.vc.bgPhotosArray = bgPhotosArray
//        self.vc.fgPhotosArray = fgPhotosArray
//        self.vc.transistion = transistion
  

 
        
    }
    
    func setTranssitionsFromURL() {
        
        self.vc.fgFPS = []
        self.vc.transistion = []
        self.fgBGRemoved = []
        self.fgFramesRemoved = []
        
        let templateGenerator = templateGenerator.shared
        
       let newTemplatesList = templateGenerator.JSONExtractorTesting(fileName: "jsontestFile")
        
        /// only for 1 template
        
        let template1 = newTemplatesList.first?.Templates.first!
        
        self.counterLabel.text = "Data is \(template1)"
        
        
        
        /// Mark: Modifying the params
        ///
        
        pickerSelectionLimit = template1!.n_images
        self.vc.imagesPerSecond = Double(template1!.bg_duration)// might have to remoe this since it might casue errors, in code “imagesPerSecond”
        
        let br = BackgroundRemoval()
        
        for frame in template1!.frames {
            
//            self.vc.fgFrameDur = template1?.frames.first?.transition_duration
            self.vc.fgFPS.append(frame.transition_duration)
            self.vc.transistion.append(transsitionConverter(trn: frame.transition))
            
            self.fgBGRemoved.append(frame.isBgToBeRemoved)
            self.fgFramesRemoved.append(frame.fg_frame_index)
            
            
        }
        
        
        
     
        
        
         
        
        
    }
    
    func transsitionConverter(trn: String) -> Transistions {
        switch (trn) {
        case "LeftToRight":
            return Transistions.leftToRight
        case "RightToLeft":
            return Transistions.rightToLeft
        case "TopToBottom":
            return Transistions.topToBottom
        case "BottomToTop":
            return Transistions.bottomToTop
        default:
            return Transistions.bottomToTop
        }
    }
    @IBAction func modelBtnClick(_ sender: Any) {
        
        self.present(DynamicViewController(), animated: true)
        
        
        print("=== \(self.selectedImages)")
        
//        DispatchQueue.main.async {
//            self.spinner.startAnimating()
//        }
//
//        self.setTranssitionsFromURL()
//        self.vc.bgPhotosArray = selectedImages
//
        
//        let transistion = [Transistions.leftToRight, Transistions.DiagonalTBLR,Transistions.bottomToTop,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight,Transistions.leftToRight]
//
//        let t = transistionCreator(bgPhotosArray: selectedImages)
//        t.SequentialCaller(transistions: transistion) {
//            url in
//
//            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
//                self.playVideo(url: url)
//            }
//        }
//        DispatchQueue.main.async {
//                        self.spinner.stopAnimating()
////                        self.playVideo(url: url)
//                    }
        
//        print("=== done")
    }
    
    
    @IBAction func btnClick(_ sender: Any) {
        
//        DispatchQueue.main.async {
//            self.spinner.startAnimating()
//        }
        
        self.spinner.startAnimating()
        self.counterLabel.text = "processing"
        
        if lastPath != nil {
            // start with a file path, for example:
            

            // check if file exists
            // fileUrl.path converts file path object to String by stripping out `file://`
            
                // delete file
                do {
                    try FileManager.default.removeItem(atPath: lastPath!)
                } catch {
                    print("Could not delete file, probably read-only filesystem")
                }
            
                
        }
        
        
        let ogImage = imgView.image
        


//        let filter = CIFilter(name: "CIKaleidoscope")
//        filter?.setValue(ogImage, forKey: kCIInputImageKey)
//        filter?.setValue(CIVector(x: 120, y: 120), forKey: kCIInputCenterKey)
//        filter?.setValue(0, forKey: kCIInputAngleKey)
//        filter?.setValue(2, forKey: "inputCount")
        
//        imgView.image = UIImage(ciImage: (filter!.outputImage?.applyingFilter("CIKaleidoscope"))!)
//
//
//
//        UIView.animate(withDuration: 3, delay: 0, animations: {
//            self.imgView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
//        sleep(3)
//            self.imgView.transform = .identity
//
//        })
        
        
        
//        let filter = CIFilter(name: "CIKaleidoscope")
//        filter?.setValue(ogImage, forKey: kCIInputImageKey)
//        filter?.setValue(CIVector(x: 120, y: 120), forKey: kCIInputCenterKey)
//        filter?.setValue(0, forKey: kCIInputAngleKey)
//        filter?.setValue(2, forKey: "inputCount")
//        imgView.image = UIImage(ciImage: (filter?.outputImage!)!)
        
        self.vc.bgPhotosArray = []
        self.vc.fgPhotosArray = []
        self.vc.transistion = []
        print("=== \(selectedImages) \(selectedImages.count)")
        
        
        self.setTranssitionsFromURL()
        
        self.vc.bgPhotosArray = selectedImages
//        self.vc.fgPhotosArray = selectedImages
        
//       self.vc.buildVideoFromImageArray() { url in
//
//           let u = url
//
//            print("=== initially \(u)")
//            sleep(1)
//
//            var timeoutCounter = 0
//
//            while (self.vc.hasExported && timeoutCounter<10){
//                print("=== waiting for export")
//                sleep(3)
//                timeoutCounter += 1
//            }
//           DispatchQueue.main.async {
//               self.playVideo(url: u)
//           }
//
//        }
        var br: BackgroundRemoval? = nil
        DispatchQueue.global(qos: .background).async {
            br = BackgroundRemoval()
        }
        
        self.spinner.startAnimating()
        
        while br == nil {
            print("=== waiting")
            
            sleep(3)
                
        }
        
        for i in 0..<selectedImages.count {
//            self.vc.bgPhotosArray.append(self.vc.transparentImageAdapter())
            print("=== \(i)")
            
            if !self.fgBGRemoved[i] {
                
                self.vc.fgPhotosArray.append(self.vc.bgPhotosArray[self.fgFramesRemoved[i]])
            }
            else {
                self.vc.fgPhotosArray.append(br!.removeBackground(image: self.vc.bgPhotosArray[self.fgFramesRemoved[i]]) )
            }
        }
//        self.vc.asset = AVAsset(url: <#T##URL#>)
        self.vc.buildVideoFromImageArray(completion: { [self] url in
            self.vc.asset = AVAsset(url: self.vc.imageArrayToVideoURL as URL)
            self.vc.exportVideoWithAnimation()
            while !self.vc.hasExported {
                print("=== waiting to complete export")
                sleep(3)
            }
            self.vc.hasExported = false
//            self.vc.asset = AVAsset(url: self.vc.animatedVideoURL.absoluteURL!)
//            self.vc.exportVideoWithAnimation()
//            
//            while !self.vc.hasExported {
//                print("=== waiting to complete export")
//                sleep(3)
//            }
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.counterLabel.text = "done"
            }
            
            
            DispatchQueue.main.async {
                self.playVideo(url: self.vc.animatedVideoURL.absoluteURL!)
            }
            
        })
        
        

        
    }
    

//
//
//     /*
//        switch(counter) {
//        case 1:
//
//            let vc = VideoCreatorGeneralised()
//            let url = vc.buildVideoFromImageArray(transistion: .optacityRL)
//        case 2:
//                let vc = VideoCreatorGeneralised()
//                let url = vc.buildVideoFromImageArray(transistion: .optacityLR)
//        case 3:
//            let vc = VideoCreatorGeneralised()
//            let url = vc.buildVideoFromImageArray(transistion: .optacityBT)
//        case 4:
//                let vc = VideoCreatorGeneralised()
//                let url = vc.buildVideoFromImageArray(transistion: .optacityLR)
//        case 5:
//            let vc = VideoCreatorGeneralised()
//            let url = vc.buildVideoFromImageArray(transistion: .bottomToTop)
//        case 6:
//            let vc = VideoCreatorGeneralised()
//            let url = vc.buildVideoFromImageArray(transistion: .scaleBSB)
//        case 7:
//            let vc = VideoCreatorGeneralised()
//            let url = vc.buildVideoFromImageArray(transistion: .topToBottom)
//        case 8:
//            let vc = VideoCreatorGeneralised()
//            let url = vc.buildVideoFromImageArray(transistion: .scaleSBS)
//        case 9:
//            let vc = VideoCreatorGeneralised()
//            let url = vc.buildVideoFromImageArray(transistion: .rightToLeft)
//        case 10:
//            let vc = VideoCreatorGeneralised()
//            let url = vc.buildVideoFromImageArray(transistion: .leftToRight)
//        default:
//            print("default")
//            let vc = VideoCreatorGeneralised()
//            let url = vc.buildVideoFromImageArray(transistion: .optacityRL)
//        }
// */
//
////        let url = anim.animate()
//        let nsUrl = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video2.mp4")
////
////        if (url != nil) {
////        } else {
////            print("url is nil \(nsUrl)")
////        }
//
//        print("animation completed")
//        counter += 1
//        counterLabel.text = "iteration is \(counter-1)"
//
//        playVideo(url: nsUrl.absoluteURL!)
//
//
//    }
//
    private func playVideo(url: URL) {
        
        lastPath = url.absoluteString

        var timeoutCounter = 0

//        while (!self.vc.hasExported && timeoutCounter <= 10) {
//            print("=== waiting to complete export")
//            timeoutCounter += 1
//            sleep(3)
//
//        }
//
//        if (timeoutCounter == 10) {
//            print("=== timed out")
//            self.vc.hasExported = false
//            return
//        }

        print("=== playing \(url)")
        let videoURL = url
        let player = AVPlayer(url: videoURL)
//        var playerLayer = AVPlayerLayer (player: player)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player


        let asset = AVAsset(url: videoURL)
        if asset.isReadable {
            // the asset is readable, proceed to check if it has a video track
            print("=== video is readable")
        } else {
            // the asset is not readable, it may be corrupted or inaccessible
            print("=== video is corrupted")

            do {
                try FileManager.default.removeItem(at: videoURL)
                print("=== Video file deleted successfully.")
            } catch {
                print("Error deleting video file: \(error.localizedDescription)")
            }
        }
        let videoTracks = asset.tracks(withMediaType: .video)
        if videoTracks.count > 0 {
            // the asset has at least one video track
            print("=== video has a video track")
        } else {
            // the asset does not have any video tracks, it may be corrupted or not a valid video file
            print("=== video has no video track")
        }

    
        
       

//        var videoPlayer = AVPlayer(url: videoURL)
//                var playerLayer2 = AVPlayerLayer(player: videoPlayer)
//                playerLayer2.frame = view.bounds
//                view.layer.addSublayer(playerLayer2)
//                videoPlayer.play()
//
//
        present(playerViewController, animated: true) {
            player.play()
        }


//        print("===  \(videoPlayer.status)")
//        sleep(3)
//        print("=== replacing")
//

//        playerLayer.frame = self.view.bounds
//        playerLayer.videoGravity = .resizeAspect
//        self.view.layer.addSublayer(playerLayer)
//        player.play()
    }
    
    
    @IBAction func imagePicker(_ sender: Any) {
        selectedImages = []
        
        var configuration = PHPickerConfiguration()
               configuration.filter = .images
        configuration.selectionLimit = self.pickerSelectionLimit // set to 0 for unlimited selection
               
               let picker = PHPickerViewController(configuration: configuration)
               picker.delegate = self
               present(picker, animated: true, completion: nil)
    }
    
    // Method called when AVPlayerItemDidPlayToEndTime notification is received
    @objc func playerDidFinishPlaying(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        videoPlayer.replaceCurrentItem(with: nil)
        playerItem.seek(to: .zero, completionHandler: nil)
        dismiss(animated: true, completion: nil)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
           dismiss(animated: true, completion: nil)
           
           for result in results {
               if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                   result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                       guard let self = self, let image = image as? UIImage else {
                           return
                       }
                       
                       DispatchQueue.main.async {
                           self.selectedImages.append(image)
                           // do something with the selectedImages array, such as displaying the images in a collection view
                       }
                   }
               }
           }
       }
       
       func pickerDidCancel(_ picker: PHPickerViewController) {
           dismiss(animated: true, completion: nil)
       }
}

