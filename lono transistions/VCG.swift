//
//  VCG.swift
//  lono transistions
//
//  Created by Priyam Mehta on 16/05/23.
//

import Foundation
import AVFoundation
import AVKit

class transistionCreator {

    var fgPhotosArray: [UIImage]
    let bgPhotosArray: [UIImage]
    let outputSize: CGSize
 
    init(bgPhotosArray: [UIImage]) {
        self.fgPhotosArray = [UIImage]()
        self.outputSize = CGSize(width: 1440, height: 2560) // the output video size, 9:16 ratio
        self.bgPhotosArray = bgPhotosArray
        
    }
    
    func BGVideoGenerator() -> URL {
        // do smoething here
        var exportedFile: URL? = nil
        
        let settings = CXEImagesToVideo.videoSettings(codec: AVVideoCodecType.h264.rawValue, width: (bgPhotosArray[0].cgImage?.width)!, height: (bgPhotosArray[0].cgImage?.height)!)

        let movieMaker = CXEImagesToVideo(videoSettings: settings)
        movieMaker.createMovieFrom(images: bgPhotosArray) { (fileURL: URL) in
            print("=== \(fileURL)")
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               exportedFile = fileURL
//            }
        }
        while exportedFile == nil {
            sleep(1)
        }
        return exportedFile!
    }

    func FGVideoGenerator(videoTrack: AVAssetTrack, transistion: [Transistions] ) -> AVMutableVideoComposition {
        // do something ehre
        let size = videoTrack.naturalSize
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        // MARK: this is the animation part
        var parentlayer = animation(videolayer: videolayer, videoTrack: videoTrack, transistons: transistion)
        
        // MARK: this is the exporting part
        /// #handling the layer composition for export here
        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30) // time HERE
        layercomposition.renderSize = size
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
      return layercomposition
    }

    func finalSticher(initialVideoTrack videoTrack: AVAssetTrack, initialVideoTimerange timerange:CMTimeRange, AnimatedFGLayer layercomposition: AVMutableVideoComposition ,completion: @escaping (_ exported: Bool, _ exportURL: URL?) -> Void) {
        // do something ehre
        
        let opVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/videoFinal\(Int.random(in: 1000..<1000000))\(Int.random(in: 0..<10000)).mp4") // Creating a final fg video op url
        
        // MARK: BG Video from asset creation
        let composition = AVMutableComposition()
        let compositionVideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }
        
        // MARK: FG asset export process
        // FG Layer settings
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = [layerinstruction]
        layercomposition.instructions = [instruction]
        
        // FG asset export
        guard let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { return  }
        assetExport.videoComposition = layercomposition
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = opVideoURL as URL
        assetExport.exportAsynchronously(completionHandler: {
            switch assetExport.status {
            case AVAssetExportSession.Status.failed:
                print("=== failed \(String(describing: assetExport.error))")
//                self.ExportFailed = true
                completion(false, nil)
            case AVAssetExportSession.Status.cancelled:
                print("=== cancelled \(String(describing: assetExport.error))")
                completion(false, nil)
            default:
                print("=== Exported  at \(opVideoURL.absoluteString)")
//                self.hasExported = true
                completion(true, opVideoURL.absoluteURL)
            }
        })
    }
    
    func finalSticher2(asset: AVAsset, transistion: [Transistions] ,completion: @escaping (_ exported: Bool, _ exportURL: URL?) -> Void) {
        let opVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/videoFinal\(Int.random(in: 1000..<1000000))\(Int.random(in: 0..<10000)).mp4") // Creating a final fg video op url

        let composition = AVMutableComposition()
        let track = asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack: AVAssetTrack = track[0] as AVAssetTrack
        let timerange = CMTimeRangeMake(start: CMTime.zero, duration: (asset.duration))
        let compositionVideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }
        
        let size = videoTrack.naturalSize
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        // MARK: this is the animation part
        var parentlayer = animation(videolayer: videolayer, videoTrack: videoTrack, transistons: transistion)
        
        // MARK: this is the exporting part
        /// #handling the layer composition for export here
        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30) // time HERE
        layercomposition.renderSize = size
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = [layerinstruction]
        layercomposition.instructions = [instruction]
        
        /// #handling the export to the given URL here
//        removeFileAtURLIfExists(url: self.animatedVideoURL)

        guard let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { return  }
        assetExport.videoComposition = layercomposition
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = opVideoURL as URL
        assetExport.exportAsynchronously(completionHandler: {
            switch assetExport.status {
            case AVAssetExportSession.Status.failed:
                print("=== failed \(String(describing: assetExport.error))")
                completion(false, nil)
            case AVAssetExportSession.Status.cancelled:
                print("=== cancelled \(String(describing: assetExport.error))")
                completion(false, nil)
            default:
                print("=== Exported  at \(opVideoURL)")
                completion(true, opVideoURL.absoluteURL)
            }
        })
    }
        
        
    

    func SequentialCaller(transistions: [Transistions], completion: @escaping   (URL) -> Void) {
        // call all three in succession
        
        let br = BackgroundRemoval()
        self.fgPhotosArray = [UIImage]()
        for i in 0..<bgPhotosArray.count {
            print("=== \(i)")
            self.fgPhotosArray.append(br.removeBackground(image: self.bgPhotosArray[i]))
        }
        
        let bgURL = self.BGVideoGenerator()
        let VT = generateVideoTrackFromAsset(asset:  AVAsset(url: bgURL as URL))
        let videoTrack = VT.0
        let videoTrackTimeRange = VT.1
        
        let fgLayer = self.FGVideoGenerator(videoTrack: videoTrack, transistion: transistions)
        
//        finalSticher(initialVideoTrack: videoTrack, initialVideoTimerange: videoTrackTimeRange, AnimatedFGLayer: fgLayer) {
//            (success, url) in
//
//            if !success {
//                print("=== export failed \(url)")
//            }
//
//            completion(url!)
//        }
        
        finalSticher2(asset: AVAsset(url: bgURL as URL), transistion: transistions) {
            (success, url) in
            
            if !success {
                print("=== export failed \(url)")
            }
            
            completion(url!)
        }
        
    }
    
    
    // MARK: Extra func
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    func generateVideoTrackFromAsset(asset: AVAsset) -> (AVAssetTrack, CMTimeRange) {
        
        let track = asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack: AVAssetTrack = track[0] as AVAssetTrack
        let timerange = CMTimeRangeMake(start: CMTime.zero, duration: (asset.duration))
        return (videoTrack, timerange)
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    
    
    
    
    
    
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Animation class
    func animation(videolayer: CALayer, videoTrack: AVAssetTrack, transistons: [Transistions]) -> CALayer {
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        var transiston = transistons

        let size = videoTrack.naturalSize
        var parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)


        print("=== \(transiston)")
        //this is the animation part
        var time = [Double]() //I used this time array to determine the start time of a frame animation. Each frame will stay for 3 secs, thats why their difference is 3

        for image in 0..<self.fgPhotosArray.count { // adding animation to each fg image frame

            if image != 0 { // Setting the duration of each frame here -> 3 for 3s
                time.append(1 * Double(image)) // FPS for FG HERE
            } else {
                time.append(0.00001)
            }
            print("=== fg has \(self.fgPhotosArray.count) and bg has \(self.bgPhotosArray.count)")

            let nextPhoto = self.fgPhotosArray[image]

            let horizontalRatio = CGFloat(self.outputSize.width) / nextPhoto.size.width
            let verticalRatio = CGFloat(self.outputSize.height) / nextPhoto.size.height
            let aspectRatio = min(horizontalRatio, verticalRatio)
            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
            let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
            let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0

            if (image > (transiston.count - 1)) {
                transiston.append(.bottomToTop)
            }
            print("=== animation is \(transiston[image]), index \(image), image is \(self.fgPhotosArray[image])")


            switch(transiston[image]) {
            case .leftToRight:
                ///#1. left->right///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation = CABasicAnimation()
                animation.keyPath = "position.x"
                animation.fromValue = -videoTrack.naturalSize.width
                animation.toValue = (videoTrack.naturalSize.width) / 2
                animation.duration = 1
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                blackLayer.add(animation, forKey: "basic")


                parentlayer.addSublayer(blackLayer)

            case .rightToLeft:
                ///#2. right->left///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation = CABasicAnimation()
                animation.keyPath = "position.x"
                animation.fromValue = videoTrack.naturalSize.width
                animation.toValue = (videoTrack.naturalSize.width) / 2
                animation.duration = 1
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                blackLayer.add(animation, forKey: "basic")


                parentlayer.addSublayer(blackLayer)

            case .topToBottom:
                ///#3. top->bottom///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: 0, y: 2 * videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation = CABasicAnimation()
                animation.keyPath = "position.y"
                animation.fromValue = 2 * videoTrack.naturalSize.height
                animation.toValue = (videoTrack.naturalSize.height) / 2
                animation.duration = 1
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                blackLayer.add(animation, forKey: "basic")

                parentlayer.addSublayer(blackLayer)

            case .bottomToTop:
                ///#4. bottom->top///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: 0, y: -videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation = CABasicAnimation()
                animation.keyPath = "position.y"
                animation.fromValue = -videoTrack.naturalSize.height
                animation.toValue = (videoTrack.naturalSize.height) / 2
                animation.duration = 1
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                blackLayer.add(animation, forKey: "basic")

                parentlayer.addSublayer(blackLayer)

            case .optacityLR:
                ///#5. opacity(1->0)(left->right)///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation = CABasicAnimation()
                animation.keyPath = "position.x"
                animation.fromValue = -videoTrack.naturalSize.width
                animation.toValue = (videoTrack.naturalSize.width) / 2
                animation.duration = 1
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                blackLayer.add(animation, forKey: "basic")

                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1
                fadeOutAnimation.toValue = 0
                fadeOutAnimation.duration = 3
                fadeOutAnimation.beginTime = CFTimeInterval(time[image])
                fadeOutAnimation.isRemovedOnCompletion = true
                blackLayer.add(fadeOutAnimation, forKey: "opacity")

                parentlayer.addSublayer(blackLayer)

            case .optacityRL:
                ///#6. opacity(1->0)(right->left)///

                let transparentLayer = CALayer()
                transparentLayer.frame = CGRect(x: 2 * videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                transparentLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                transparentLayer.addSublayer(imageLayer)

                let animation = CABasicAnimation()
                animation.keyPath = "position.x"
                animation.fromValue = 2 * videoTrack.naturalSize.width
                animation.toValue = (-videoTrack.naturalSize.width) / 2
                animation.duration = 1
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                transparentLayer.add(animation, forKey: "basic")

                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1
                fadeOutAnimation.toValue = 0
                fadeOutAnimation.duration = 3
                fadeOutAnimation.beginTime = CFTimeInterval(time[image])
                fadeOutAnimation.isRemovedOnCompletion = true
                transparentLayer.add(fadeOutAnimation, forKey: "opacity")

                parentlayer.addSublayer(transparentLayer)

            case .optacityTB:
                ///#7. opacity(1->0)(top->bottom)///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: 0, y: 2 * videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.black.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation = CABasicAnimation()
                animation.keyPath = "position.y"
                animation.fromValue = 2 * videoTrack.naturalSize.height
                animation.toValue = (-videoTrack.naturalSize.height) / 2
                animation.duration = 1
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                blackLayer.add(animation, forKey: "basic")

                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1
                fadeOutAnimation.toValue = 0
                fadeOutAnimation.duration = 3
                fadeOutAnimation.beginTime = CFTimeInterval(time[image])
                fadeOutAnimation.isRemovedOnCompletion = true
                blackLayer.add(fadeOutAnimation, forKey: "opacity")

                parentlayer.addSublayer(blackLayer)

            case .optacityBT:
                ///#8. opacity(1->0)(bottom->top)///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: 0, y: -videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.black.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation = CABasicAnimation()
                animation.keyPath = "position.y"
                animation.fromValue = -videoTrack.naturalSize.height
                animation.toValue = (videoTrack.naturalSize.height) / 2
                animation.duration = 1
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                blackLayer.add(animation, forKey: "basic")

                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1
                fadeOutAnimation.toValue = 0
                fadeOutAnimation.duration = 1
                fadeOutAnimation.beginTime = CFTimeInterval(time[image])
                fadeOutAnimation.isRemovedOnCompletion = true
                blackLayer.add(fadeOutAnimation, forKey: "opacity")

                parentlayer.addSublayer(blackLayer)

            case .scaleSB:
                ///#9. scale(small->big->small)///

                let TransparentLayer = CALayer() // layer for the fg, animated image
                TransparentLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                TransparentLayer.backgroundColor = UIColor.clear.cgColor
                TransparentLayer.opacity = 0

                let blackLayer = CALayer() // Layer for the bg image
                blackLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.black.cgColor
                blackLayer.opacity = 0

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                TransparentLayer.addSublayer(imageLayer)

                let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
                scaleAnimation.values = [0, 0.25, 0.5, 0.75, 1.0]
                scaleAnimation.beginTime = CFTimeInterval(time[image])
                scaleAnimation.duration = 1
                scaleAnimation.isRemovedOnCompletion = true
                TransparentLayer.add(scaleAnimation, forKey: "transform.scale")

                let fadeInOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeInOutAnimation.fromValue = 1
                fadeInOutAnimation.toValue = 1
                fadeInOutAnimation.duration = 1
                fadeInOutAnimation.beginTime = CFTimeInterval(time[image])
                fadeInOutAnimation.isRemovedOnCompletion = true
                TransparentLayer.add(fadeInOutAnimation, forKey: "opacity")

                parentlayer.addSublayer(TransparentLayer)

            case .scaleBSB:
                ///#10. scale(big->small->big)///

                let TransparentLayer = CALayer() // layer for the fg, animated image
                TransparentLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                TransparentLayer.backgroundColor = UIColor.clear.cgColor
                TransparentLayer.opacity = 0

                let blackLayer = CALayer() // Layer for the bg image
                blackLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.black.cgColor
                blackLayer.opacity = 0

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                TransparentLayer.addSublayer(imageLayer)

                let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
                scaleAnimation.values = [1, 0, 1]
                scaleAnimation.beginTime = CFTimeInterval(time[image])
                scaleAnimation.duration = 1
                scaleAnimation.isRemovedOnCompletion = true
                TransparentLayer.add(scaleAnimation, forKey: "transform.scale")

                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1
                fadeOutAnimation.toValue = 1
                fadeOutAnimation.duration = 1
                fadeOutAnimation.beginTime = CFTimeInterval(time[image])
                fadeOutAnimation.isRemovedOnCompletion = true
                TransparentLayer.add(fadeOutAnimation, forKey: "opacity")

                parentlayer.addSublayer(TransparentLayer)

            case .fgConstant:
                // it jsut stays there (to keep the fg or bg contstant, not to change them)

                let TransparentLayer = CALayer() // layer for the fg, animated image
                TransparentLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                TransparentLayer.backgroundColor = UIColor.clear.cgColor
                TransparentLayer.opacity = 0

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                TransparentLayer.addSublayer(imageLayer)

                parentlayer.addSublayer(TransparentLayer)
            case .bgConstant:
                // it jsut stays there (to keep the fg or bg contstant, not to change them)
                // to add/stack these images below the current layer instead of on the top

                let TransparentLayer = CALayer() // layer for the fg, animated image
                TransparentLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                TransparentLayer.backgroundColor = UIColor.clear.cgColor
                TransparentLayer.opacity = 0

                let blackLayer = CALayer() // Layer for the bg image
                blackLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.black.cgColor
                blackLayer.opacity = 0

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                TransparentLayer.addSublayer(imageLayer)

                let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
                scaleAnimation.values = [1, 0, 1]
                scaleAnimation.beginTime = CFTimeInterval(time[image])
                scaleAnimation.duration = 1
                scaleAnimation.isRemovedOnCompletion = true
                TransparentLayer.add(scaleAnimation, forKey: "transform.scale")

                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1
                fadeOutAnimation.toValue = 1
                fadeOutAnimation.duration = 1
                fadeOutAnimation.beginTime = CFTimeInterval(time[image])
                fadeOutAnimation.isRemovedOnCompletion = true
                TransparentLayer.add(fadeOutAnimation, forKey: "opacity")

                parentlayer.addSublayer(TransparentLayer)

            case .kaleidoscopeFilter:

                let ogImage = self.bgPhotosArray[image].cgImage

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let filter = CIFilter(name: "CIKaleidoscope")
                filter?.setValue(ogImage, forKey: kCIInputImageKey)
                filter?.setValue(CIVector(x: 120, y: 120), forKey: kCIInputCenterKey)
                filter?.setValue(0, forKey: kCIInputAngleKey)
                filter?.setValue(2, forKey: "inputCount")

                if filter == nil {
                    print("=== kaleidscope is nil")
                    return parentlayer
                }

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = filter?.outputImage!
                blackLayer.addSublayer(imageLayer)

                parentlayer.addSublayer(blackLayer)



            case .CIZoomBlurFilter:

                let degrees = 30.0
                let radians = CGFloat(degrees * Double.pi / 180)

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)


                let animation = CABasicAnimation(keyPath: "transform.rotation.z")
                animation.fromValue = 0
                animation.toValue = Double.pi
                animation.duration = 3 // seconds
                animation.repeatCount = 1 // repeat indefinitely
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                blackLayer.add(animation, forKey: "rotationAnimation")

                parentlayer.addSublayer(blackLayer)




            case .affineTransformationFilter:

                let degrees = 30.0
                let radians = CGFloat(degrees * Double.pi / 180)

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: videoTrack.naturalSize.width / 2, y: videoTrack.naturalSize.height / 2, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor
                blackLayer.position = CGPoint(x: videoTrack.naturalSize.width / 2, y: videoTrack.naturalSize.height / 2)


                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation = CABasicAnimation(keyPath: "transform.rotation.z")
                animation.fromValue = 0
                animation.toValue = 2 * Double.pi
                animation.duration = 3 // seconds
                animation.repeatCount = 0 // repeat indefinitely
                animation.beginTime = CFTimeInterval(time[image])
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.isRemovedOnCompletion = true
                animation.delegate?.animationDidStop!(animation, finished: true)
                blackLayer.add(animation, forKey: "rotationAnimation")

                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1
                fadeOutAnimation.toValue = 0
                fadeOutAnimation.duration = 3
                fadeOutAnimation.beginTime = CFTimeInterval(time[image])
                fadeOutAnimation.isRemovedOnCompletion = true
                blackLayer.add(fadeOutAnimation, forKey: "opacity")

                parentlayer.addSublayer(blackLayer)


            case .DiagonalBTLR:
                ///#1. left->right///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation2 = CABasicAnimation(keyPath: "position")
                animation2.fromValue = [0, 0]
                animation2.toValue = [(videoTrack.naturalSize.width) / 2, (videoTrack.naturalSize.height) / 2]
                animation2.duration = 1
                animation2.beginTime = CFTimeInterval(time[image])
                animation2.fillMode = CAMediaTimingFillMode.forwards
                animation2.isRemovedOnCompletion = true

                blackLayer.add(animation2, forKey: "position")


                parentlayer.addSublayer(blackLayer)

            case .DiagonalTBLR:
                ///#1. left->right///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation2 = CABasicAnimation(keyPath: "position")
                animation2.fromValue = [0, videoTrack.naturalSize.height]
                animation2.toValue = [(videoTrack.naturalSize.width) / 2, (videoTrack.naturalSize.height) / 2]
                animation2.duration = 1
                animation2.beginTime = CFTimeInterval(time[image])
                animation2.fillMode = CAMediaTimingFillMode.forwards
                animation2.isRemovedOnCompletion = true

                blackLayer.add(animation2, forKey: "position")


                parentlayer.addSublayer(blackLayer)

            case .DiagonalTBRL:
                ///#2. right->left///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation2 = CABasicAnimation(keyPath: "position")
                animation2.fromValue = [videoTrack.naturalSize.width, videoTrack.naturalSize.height]
                animation2.toValue = [(videoTrack.naturalSize.width) / 2, (videoTrack.naturalSize.height) / 2]
                animation2.duration = 1
                animation2.beginTime = CFTimeInterval(time[image])
                animation2.fillMode = CAMediaTimingFillMode.forwards
                animation2.isRemovedOnCompletion = true

                blackLayer.add(animation2, forKey: "position")


                parentlayer.addSublayer(blackLayer)

            case .DiagonalBTRL:
                ///#2. right->left///

                let blackLayer = CALayer()
                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor

                let imageLayer = CALayer()
                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                imageLayer.contents = self.fgPhotosArray[image].cgImage
                blackLayer.addSublayer(imageLayer)

                let animation2 = CABasicAnimation(keyPath: "position")
                animation2.fromValue = [videoTrack.naturalSize.width, -videoTrack.naturalSize.height]
                animation2.toValue = [(videoTrack.naturalSize.width) / 2, (videoTrack.naturalSize.height) / 2]
                animation2.duration = 1
                animation2.beginTime = CFTimeInterval(time[image])
                animation2.fillMode = CAMediaTimingFillMode.forwards
                animation2.isRemovedOnCompletion = true

                blackLayer.add(animation2, forKey: "position")


                parentlayer.addSublayer(blackLayer)


            }

        }
        return parentlayer
    }


}
