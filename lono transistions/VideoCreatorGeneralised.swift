//
//  VideoTransistionEngine.swift
//  lono
//
//  Created by Priyam Mehta on 06/03/23.
//

import Foundation
import AVFoundation
import AVKit

enum Transistions {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
    case optacityLR
    case optacityRL
    case optacityTB
    case optacityBT
    case scaleSB
    case scaleBSB
    case kaleidoscopeFilter
    case CIZoomBlurFilter
    case affineTransformationFilter
    case DiagonalBTLR
    case DiagonalTBLR
    case DiagonalBTRL
    case DiagonalTBRL
    case fgConstant
    case bgConstant

}

class VideoCreatorGeneralised {

    let outputSize: CGSize
    var imagesPerSecond: TimeInterval // the BG FPS / BG Duration
    var bgPhotosArray: [UIImage]
    var fgPhotosArray: [UIImage]
    var transistion: [Transistions]
    var imageArrayToVideoURL: NSURL
    var animatedVideoURL: NSURL
    let audioIsEnabled: Bool
    var fgFrameDur: Int64

    var fgFPS: [Double]
    var asset: AVAsset! // op of the first bg video track, made using func BVFIA
    var hasExported: Bool // a random bool to make sure the video is exported, to finally give output
    var ExportFailed: Bool // a random bool to make sure the video is exported, to finally give output
    var currentProgress: Int // a string to indiciate progress - ranges from 1-10
    var transparentPhotosList: [Int]
    var all: [Int : [Any]]

    init(
        outputSize: CGSize = CGSize(width: 1440, height: 2560), // the output video size, 9:16 ratio
        imagesPerSecond: TimeInterval = 1,
        bgPhotosArray: [UIImage] = [UIImage](),
        fgPhotosArray: [UIImage] = [UIImage](),
        transistion: [Transistions] = [Transistions](),
        imageArrayToVideoURL: NSURL = NSURL(),
        animatedVideoURL: NSURL = NSURL(),
        fgFrameDur: Int64 = 1, // duration of each fg frame
        
        fgFPS: [Double] = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,], // fg frame duration here
        
        audioIsEnabled: Bool = false,
        transparentPhotosList: [Int] = [Int](),
        all: [Int : [Any]] = [:]
    ) {
        self.outputSize = outputSize
        self.imagesPerSecond = imagesPerSecond //each image will be stay for 3 secs
        self.bgPhotosArray = bgPhotosArray
        self.fgPhotosArray = fgPhotosArray
        self.transistion = transistion
        self.imageArrayToVideoURL = imageArrayToVideoURL
        self.animatedVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video2.mp4")
        self.fgFrameDur = fgFrameDur
        
        self.fgFPS = fgFPS
        self.audioIsEnabled = audioIsEnabled //if your video has no sound
        self.hasExported = false
        self.ExportFailed = false
        self.currentProgress = 1
        self.transparentPhotosList = transparentPhotosList
        self.all = all
        print("=== \(self.animatedVideoURL.absoluteURL) ")
    }

    func buildVideoFromImageArray(completion: @escaping (_ url: URL) -> Void) -> URL? {
        // MARK: Main function
        /// #This works by making a video from bg images, by stiching them together.
        ///  after which it calls the exportVideoWithAnimation method
        ///
        // MARK: test values generator /////////////////////////
//        for image in 1..<6 { // setting up the bg images
//            self.bgPhotosArray.append(UIImage(named: "\(image).JPG")!) //name of the images: 1.JPG, 2.JPG, 3.JPG, 4.JPG, 5.JPG
//            print(self.bgPhotosArray[image-1])
//        }
//
//        for image in 6..<11 { // setting up the fg images
//            self.fgPhotosArray.append(UIImage(named: "\(image).JPG")!) // next 5 images
//            self.transistion.append(.leftToRight)
//
//        }
//        print("=== \(self.fgPhotosArray)")
        ////////////////////////////////////////////////
        self.hasExported = false
        
        imageArrayToVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video1\(self.random(digits: 6)).MP4") // the bg images array
        removeFileAtURLIfExists(url: imageArrayToVideoURL)
        guard let videoWriter = try? AVAssetWriter(outputURL: imageArrayToVideoURL as URL, fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter error")
        }
        let outputSettings = [AVVideoCodecKey: AVVideoCodecH264, AVVideoWidthKey: NSNumber(value: Float(outputSize.width)), AVVideoHeightKey: NSNumber(value: Float(outputSize.height))] as [String: Any]
        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            fatalError("=== Negative : Can't apply the Output settings...")
        }

        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let sourcePixelBufferAttributesDictionary = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB), kCVPixelBufferWidthKey as String: NSNumber(value: Float(outputSize.width)), kCVPixelBufferHeightKey as String: NSNumber(value: Float(outputSize.height))]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        
        self.currentProgress = 2 // updating progress
        
        // MARK: Video creation for bg starts here
        if videoWriter.startWriting() {
            let zeroTime = CMTimeMake(value: Int64(imagesPerSecond), timescale: Int32(1))
            videoWriter.startSession(atSourceTime: zeroTime)

            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            let media_queue = DispatchQueue(label: "mediaInputQueue")
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                let fps: Int32 = 1 // bg speed
                let framePerSecond: Int64 = Int64(self.imagesPerSecond)
                let frameDuration = CMTimeMake(value: Int64(self.imagesPerSecond), timescale: fps)
                var frameCount: Int64 = 0
                var appendSucceeded = true

                for i in 0..<(self.bgPhotosArray.count) {

                    if (videoWriterInput.isReadyForMoreMediaData) {
                        let nextPhoto = self.bgPhotosArray[i]
                        let lastFrameTime = CMTimeMake(value: frameCount * framePerSecond, timescale: fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        if let pixelBuffer = pixelBuffer, status == 0 {
                            let managedPixelBuffer = pixelBuffer
                            CVPixelBufferLockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
                            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGContext(data: data, width: Int(self.outputSize.width), height: Int(self.outputSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(managedPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                            context!.clear(CGRect(x: 0, y: 0, width: CGFloat(self.outputSize.width), height: CGFloat(self.outputSize.height)))
                            let horizontalRatio = CGFloat(self.outputSize.width) / nextPhoto.size.width
                            let verticalRatio = CGFloat(self.outputSize.height) / nextPhoto.size.height
                            //let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
                            let aspectRatio = min(horizontalRatio, horizontalRatio) // ScaleAspectFit
                            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
                            let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
                            let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0
                            context?.draw(nextPhoto.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)

                        } else {
                            print("=== Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        break
                    }
                    frameCount += 1
                }
                
                self.currentProgress = 3
                
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting { () -> Void in
                    print("-----video1 url = \(self.imageArrayToVideoURL)")

                    self.asset = AVAsset(url: self.imageArrayToVideoURL as URL)
                    print("=== selectedPhotosArray \(self.bgPhotosArray) ")
//                    self.exportVideoWithAnimation()
                    
//                    while !self.hasExported {
//                        print("=== waiting to complete export 2")
//                        sleep(3)
//                    }
                    print("=== opURL \(self.animatedVideoURL)")
                    completion(self.animatedVideoURL.absoluteURL!)
                }
            })
        }
        return self.animatedVideoURL.absoluteURL
    }

    func removeFileAtURLIfExists(url: NSURL) {
        if let filePath = url.path {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                do {
                    try fileManager.removeItem(atPath: filePath)
                    print("=== file removed")
                } catch let error as NSError {
                    print("=== Couldn't remove existing destination file: \(error)")
                }
            }
        }
    }

    func exportVideoWithAnimation() -> URL? {
        
        self.animatedVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video2\(self.random(digits: 6)).mp4") // Creating a final fg video op url

        let composition = AVMutableComposition()

        let track = asset?.tracks(withMediaType: AVMediaType.video)
        let videoTrack: AVAssetTrack = track![0] as AVAssetTrack
        let timerange = CMTimeRangeMake(start: CMTime.zero, duration: (asset?.duration)!)
        let compositionVideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!

        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }

        //if your video has sound, you don’t need to check this
        if audioIsEnabled {
            let compositionAudioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!

            for audioTrack in (asset?.tracks(withMediaType: AVMediaType.audio))! {
                do {
                    try compositionAudioTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: CMTime.zero)
                } catch {
                    print(error)
                }
            }
        }
        
        self.currentProgress = 4
        
        let size = videoTrack.naturalSize
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        
        self.currentProgress = 5
        // MARK: this is the animation part
        var parentlayer = animation(videolayer: videolayer, videoTrack: videoTrack, transistons: self.transistion, durmation: fgFPS )
        
        self.currentProgress = 6

        // MARK: this is the exporting part
        /// #handling the layer composition for export here
        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: self.fgFrameDur, timescale: 30) // time HERE
        layercomposition.renderSize = size
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = [layerinstruction]
        layercomposition.instructions = [instruction]
        
        self.currentProgress = 9

        /// #handling the export to the given URL here
//        removeFileAtURLIfExists(url: self.animatedVideoURL)

        guard let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { return nil }
        assetExport.videoComposition = layercomposition
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = self.animatedVideoURL as URL
        assetExport.exportAsynchronously(completionHandler: {
            switch assetExport.status {
            case AVAssetExportSession.Status.failed:
                print("=== failed \(String(describing: assetExport.error))")
                self.currentProgress = 10
                self.ExportFailed = true
                
            case AVAssetExportSession.Status.cancelled:
                print("=== cancelled \(String(describing: assetExport.error))")
                self.currentProgress = 10
            default:
                print("=== Exported  at \(self.animatedVideoURL)")
                self.hasExported = true
                self.currentProgress = 10
            }
        })
        print("--- \(self.animatedVideoURL.absoluteURL) \(self.animatedVideoURL) \(self.animatedVideoURL.isFileURL)")
        return self.animatedVideoURL.absoluteURL
    }

    func animation(videolayer: CALayer, videoTrack: AVAssetTrack, transistons: [Transistions], durmation: [Double]) -> CALayer {
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        var transiston = transistons
                
//        for t in stride(from: transiston.count - 1, through: 0, by: -1) {
//            if self.transparentPhotosList.contains(t+1){
//                print("=== skipping \(self.transparentPhotosList) \(t)")
//                transiston.insert(.bgConstant, at: t+1)
//                self.transparentPhotosList.remove(at: self.transparentPhotosList.firstIndex(of: t+1)!)
//            }
//        }
        let size = videoTrack.naturalSize
        var parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)

        
        if !self.transparentPhotosList.isEmpty {
            print("=== it is not ")
//            for t in 0..<self.transparentPhotosList.count-1 {
//
//                print("=== skipping \(self.transparentPhotosList) \(self.transparentPhotosList[t])")
//                transiston.insert(.bgConstant, at: self.transparentPhotosList[t])
//            }
        }
        print("=== trnsistions are \(transiston)")
        //this is the animation part
        var time = [Double]() //I used this time array to determine the start time of a frame animation. Each frame will stay for 3 secs, thats why their difference is 3

        for image in 0..<self.fgPhotosArray.count { // adding animation to each fg image frame

            if image != 0 { // Setting the start time of each animation -> 3 for 3s
                time.append(Double(self.imagesPerSecond)   * Double(image)) // FPS for FG HERE
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
            print("=== animation is \(transiston[image]), index \(image), image is \( self.fgPhotosArray[image])")
            
        
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
                animation.duration = durmation[image] // duration of FG
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
                animation.duration = durmation[image] // duration of FG
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
                animation.duration = durmation[image] // duration of FG
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
                animation.duration = durmation[image] // duration of FG
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
                animation.duration = durmation[image] // duration of FG
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
                animation.duration = durmation[image] // duration of FG
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
                animation.duration = durmation[image] // duration of FG
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
                animation.duration = durmation[image] // duration of FG
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
                scaleAnimation.values = [0,0.25,0.5,0.75,1.0]
                scaleAnimation.beginTime = CFTimeInterval(time[image])
                scaleAnimation.duration = durmation[image]/2 // duration of FG
                scaleAnimation.isRemovedOnCompletion = true
                TransparentLayer.add(scaleAnimation, forKey: "transform.scale")

                let fadeInOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeInOutAnimation.fromValue = 1
                fadeInOutAnimation.toValue = 1
                fadeInOutAnimation.duration = durmation[image]/2 // duration of FG
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
                scaleAnimation.duration = durmation[image]/2 // duration of FG
                scaleAnimation.isRemovedOnCompletion = true
                TransparentLayer.add(scaleAnimation, forKey: "transform.scale")

                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1
                fadeOutAnimation.toValue = 1
                fadeOutAnimation.duration = durmation[image]/2 // duration of FG
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
                blackLayer.frame = CGRect(x: videoTrack.naturalSize.width/2, y: videoTrack.naturalSize.height/2, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                blackLayer.backgroundColor = UIColor.clear.cgColor
                blackLayer.position = CGPoint(x: videoTrack.naturalSize.width/2, y: videoTrack.naturalSize.height/2)
                

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
                animation2.toValue = [(videoTrack.naturalSize.width) / 2, (videoTrack.naturalSize.height)/2]
                animation2.duration = durmation[image] // duration of FG
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
                animation2.toValue = [(videoTrack.naturalSize.width) / 2, (videoTrack.naturalSize.height)/2]
                animation2.duration = durmation[image] // duration of FG
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
                animation2.toValue = [(videoTrack.naturalSize.width) / 2, (videoTrack.naturalSize.height)/2]
                animation2.duration = durmation[image] // duration of FG
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
                animation2.toValue = [(videoTrack.naturalSize.width) / 2, (videoTrack.naturalSize.height)/2]
                animation2.duration = durmation[image] // duration of FG
                animation2.beginTime = CFTimeInterval(time[image])
                animation2.fillMode = CAMediaTimingFillMode.forwards
                animation2.isRemovedOnCompletion = true
                
                blackLayer.add(animation2, forKey: "position")


                parentlayer.addSublayer(blackLayer)
                

            }

        }
        return parentlayer
    }
    
    


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// #Adapters
//class TransisitionEngineAdapter {
    // TODO: #1 to combine bg and mask and add to bg array
    // TODO: #2 to combine fg and mask and add to fg array
    // TODO: #3 to make a function the returns the last appended image


//    var bgPhotosArray: [UIImage]
//    var fgPhotosArray: [UIImage]
//    var transistion: [Transistions]
//
//    init(bgPhotosArray: [UIImage], fgPhotosArray: [UIImage], transistion: [Transistions]) {
//        self.bgPhotosArray = bgPhotosArray
//        self.fgPhotosArray = fgPhotosArray
//        self.transistion = transistion
//    }

    func lastBgImageAdapter() -> UIImage {
        // this is the last image, could be  fg to check if we need diff var for both, but it would clash
        print("=== is bg transparent \(self.fgPhotosArray.last!)")
        return self.bgPhotosArray.last ?? transparentImageAdapter()
    }

    func lastFgImageAdapter() -> UIImage {
        // this is the last image, could be  fg, to check if we need diff var for both, but it would clash
        print("=== is fg transparent \(self.fgPhotosArray.last!)")
        return self.fgPhotosArray.last ?? transparentImageAdapter()
    }

    func transparentImageAdapter() -> UIImage {
        return UIImage(ciImage: CIImage(color: .clear)).scalingAndCropping(for: CGSize(width: 1440, height: 2560)) // adding a transparent image, in cases where we just want the bg and no fg, then add this as fg there
    }
    
    func transparentLayerAdapter(parentlayer: CALayer) -> CALayer {
        let transparentLayer = CALayer()
        transparentLayer.backgroundColor = UIColor.clear.cgColor


        parentlayer.addSublayer(transparentLayer)

        return parentlayer


    }
    func bgMaskAdapter(bgImg: UIImage, MaskImg: UIImage) {
        /// #adds mask to the bg img and returns that image
    }

    func fgMaskAdapter(fgImg: UIImage, MaskImg: UIImage) {
        /// #adds the mask to the fg and returns that image
    }


    private func random(digits: Int) -> String {
        var number = String()
        for _ in 1...digits {
            number += "\(Int.random(in: 1...9))"
        }
        print("Generated Number is \(number)")
        return number
    }

    private func getRandomNumber() -> Int {
        return Int.random(in: 140..<180)
    }


    func animationDidStop(_ anim: CAAnimation, finished flag: Bool, backLayer: CALayer) {
        backLayer.removeFromSuperlayer()
    }
    
    func handleTransparentImageTransistionAdapter(transistion: [Transistions], transparentPhotosList: [Int: [Any]]) -> [Int: [Any]] {
        // TODO: #1 complete this
        var transparentPhotosList = transparentPhotosList
        var transistion = transistion
        for (k,v) in transparentPhotosList {
            if (v[2] as! Bool) == true {
                transparentPhotosList[k]!.append(Transistions.bgConstant)
                print("=== skipping \(transparentPhotosList[k]) \(k)")
            }
//            transparentPhotosList[k]!.append(Tra)
        }
        return transparentPhotosList
    }
}



