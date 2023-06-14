//
//  VideoCreator.swift
//  lono transistions
//
//  Created by Priyam Mehta on 22/02/23.
//

import Foundation
import AVFoundation
import AVKit

class VideoCreator {

    let outputSize = CGSize(width: 1920, height: 1280)
    let imagesPerSecond: TimeInterval = 3 //each image will be stay for 3 secs
    var selectedPhotosArray = [UIImage]()
    var imageArrayToVideoURL = NSURL()
    let audioIsEnabled: Bool = false //if your video has no sound
    var asset: AVAsset!

    func buildVideoFromImageArray() -> URL? {

        var opUrl: URL? = nil

        for image in 0..<5 { // using the odd images here
            selectedPhotosArray.append(UIImage(named: "\(image + 1).JPG")!) //name of the images: 1.JPG, 2.JPG, 3.JPG, 4.JPG, 5.JPG

        }

        imageArrayToVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video1.MP4")
        removeFileAtURLIfExists(url: imageArrayToVideoURL)
        guard let videoWriter = try? AVAssetWriter(outputURL: imageArrayToVideoURL as URL, fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter error")
        }
        let outputSettings = [AVVideoCodecKey: AVVideoCodecH264, AVVideoWidthKey: NSNumber(value: Float(outputSize.width)), AVVideoHeightKey: NSNumber(value: Float(outputSize.height))] as [String: Any]
        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            fatalError("Negative : Can't apply the Output settings...")
        }
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let sourcePixelBufferAttributesDictionary = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB), kCVPixelBufferWidthKey as String: NSNumber(value: Float(outputSize.width)), kCVPixelBufferHeightKey as String: NSNumber(value: Float(outputSize.height))]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        if videoWriter.startWriting() {
            let zeroTime = CMTimeMake(value: Int64(imagesPerSecond), timescale: Int32(1))
            videoWriter.startSession(atSourceTime: zeroTime)

            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            let media_queue = DispatchQueue(label: "mediaInputQueue")
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                let fps: Int32 = 1
                let framePerSecond: Int64 = Int64(self.imagesPerSecond)
                let frameDuration = CMTimeMake(value: Int64(self.imagesPerSecond), timescale: fps)
                var frameCount: Int64 = 0
                var appendSucceeded = true
                while (!self.selectedPhotosArray.isEmpty) {
                    if (videoWriterInput.isReadyForMoreMediaData) {
                        let nextPhoto = self.selectedPhotosArray.remove(at: 0)
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
                            let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
                            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
                            let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
                            let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0
                            context?.draw(nextPhoto.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        break
                    }
                    frameCount += 1
                }
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting { () -> Void in
                    print("-----video1 url = \(self.imageArrayToVideoURL)")

                    self.asset = AVAsset(url: self.imageArrayToVideoURL as URL)
                    opUrl = self.exportVideoWithAnimation()
                }
            })
        }
        return opUrl
    }

    func removeFileAtURLIfExists(url: NSURL) {
        if let filePath = url.path {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                do {
                    try fileManager.removeItem(atPath: filePath)
                } catch let error as NSError {
                    print("Couldn't remove existing destination file: \(error)")
                }
            }
        }
    }

    func exportVideoWithAnimation() -> URL? {
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

        let size = videoTrack.naturalSize

        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //this is the animation part
        var time = [0.00001, 3, 6, 9, 12] //I used this time array to determine the start time of a frame animation. Each frame will stay for 3 secs, thats why their difference is 3
        var imgarray = [UIImage]()

        for image in 0..<5 { // reappend here to overwirte
            imgarray.append(UIImage(named: "\(image + 1).JPG")!) // next 5 images
            imgarray.append(UIImage(named: "\(image + 6).JPG")!) // next 5 images

            let nextPhoto = imgarray[image]

            let horizontalRatio = CGFloat(self.outputSize.width) / nextPhoto.size.width
            let verticalRatio = CGFloat(self.outputSize.height) / nextPhoto.size.height
            let aspectRatio = min(horizontalRatio, verticalRatio)
            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
            let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
            let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0

            ///I showed 10 animations here. You can uncomment any of this and export a video to see the result.

            ///#1. left->right///
            //                let blackLayer = CALayer()
            //                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //                blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //                let imageLayer = CALayer()
            //                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //                imageLayer.contents = imgarray[image].cgImage
            //                blackLayer.addSublayer(imageLayer)
            //
            //                let animation = CABasicAnimation()
            //                animation.keyPath = "position.x"
            //                animation.fromValue = -videoTrack.naturalSize.width
            //                animation.toValue = 2 * (videoTrack.naturalSize.width)
            //                animation.duration = 3
            //                animation.beginTime = CFTimeInterval(time[image])
            //                animation.fillMode = CAMediaTimingFillMode.forwards
            //                animation.isRemovedOnCompletion = false
            //                blackLayer.add(animation, forKey: "basic")

            ///#2. right->left///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 2 * videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.x"
            //            animation.fromValue = 2 * (videoTrack.naturalSize.width)
            //            animation.toValue = -videoTrack.naturalSize.width
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")

            ///#3. top->bottom///
            //                let blackLayer = CALayer()
            //                blackLayer.frame = CGRect(x: 0, y: 2 * videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //                blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //                let imageLayer = CALayer()
            //                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //                imageLayer.contents = imgarray[image].cgImage
            //                blackLayer.addSublayer(imageLayer)
            //
            //                let animation = CABasicAnimation()
            //                animation.keyPath = "position.y"
            //                animation.fromValue = 2 * videoTrack.naturalSize.height
            //                animation.toValue = -videoTrack.naturalSize.height
            //                animation.duration = 3
            //                animation.beginTime = CFTimeInterval(time[image])
            //                animation.fillMode = CAMediaTimingFillMode.forwards
            //                animation.isRemovedOnCompletion = false
            //                blackLayer.add(animation, forKey: "basic")

            ///#4. bottom->top///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 0, y: -videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.y"
            //            animation.fromValue = -videoTrack.naturalSize.height
            //            animation.toValue = 2 * videoTrack.naturalSize.height
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")

            ///#5. opacity(1->0)(left->right)///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.x"
            //            animation.fromValue = -videoTrack.naturalSize.width
            //            animation.toValue = 2 * (videoTrack.naturalSize.width)
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")
            //
            //            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            //            fadeOutAnimation.fromValue = 1
            //            fadeOutAnimation.toValue = 0
            //            fadeOutAnimation.duration = 3
            //            fadeOutAnimation.beginTime = CFTimeInterval(time[image])
            //            fadeOutAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(fadeOutAnimation, forKey: "opacity")

            ///#6. opacity(1->0)(right->left)///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 2 * videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.x"
            //            animation.fromValue = 2 * videoTrack.naturalSize.width
            //            animation.toValue = -videoTrack.naturalSize.width
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")
            //
            //            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            //            fadeOutAnimation.fromValue = 1
            //            fadeOutAnimation.toValue = 0
            //            fadeOutAnimation.duration = 3
            //            fadeOutAnimation.beginTime = CFTimeInterval(time[image])
            //            fadeOutAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(fadeOutAnimation, forKey: "opacity")

            ///#7. opacity(1->0)(top->bottom)///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 0, y: 2 * videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.y"
            //            animation.fromValue = 2 * videoTrack.naturalSize.height
            //            animation.toValue = -videoTrack.naturalSize.height
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")
            //
            //            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            //            fadeOutAnimation.fromValue = 1
            //            fadeOutAnimation.toValue = 0
            //            fadeOutAnimation.duration = 3
            //            fadeOutAnimation.beginTime = CFTimeInterval(time[image])
            //            fadeOutAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(fadeOutAnimation, forKey: "opacity")

            ///#8. opacity(1->0)(bottom->top)///
                        let blackLayer = CALayer()
                        blackLayer.frame = CGRect(x: 0, y: -videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                        blackLayer.backgroundColor = UIColor.black.cgColor
            
                        let imageLayer = CALayer()
                        imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                        imageLayer.contents = imgarray[image].cgImage
                        blackLayer.addSublayer(imageLayer)
            
                        let animation = CABasicAnimation()
                        animation.keyPath = "position.y"
                        animation.fromValue = -videoTrack.naturalSize.height
                        animation.toValue = 2 * videoTrack.naturalSize.height
                        animation.duration = 3
                        animation.beginTime = CFTimeInterval(time[image])
            animation.fillMode = CAMediaTimingFillMode.forwards
                        animation.isRemovedOnCompletion = false
                        blackLayer.add(animation, forKey: "basic")
            
                        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                        fadeOutAnimation.fromValue = 1
                        fadeOutAnimation.toValue = 0
                        fadeOutAnimation.duration = 3
                        fadeOutAnimation.beginTime = CFTimeInterval(time[image])
                        fadeOutAnimation.isRemovedOnCompletion = false
                        blackLayer.add(fadeOutAnimation, forKey: "opacity")

            ///#9. scale(small->big->small)///
//            let blackLayer = CALayer()
//            blackLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
//            blackLayer.backgroundColor = UIColor.black.cgColor
//            blackLayer.opacity = 0
//
//            let imageLayer = CALayer()
//            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
//            imageLayer.contents = imgarray[image].cgImage
//            blackLayer.addSublayer(imageLayer)
//
//            let imageLayer2 = CALayer()
//            imageLayer2.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
//
//            if ((image + 1) > (imgarray.count-1)){
//                imageLayer2.contents = imgarray[0].cgImage
//                blackLayer.addSublayer(imageLayer2)
//            } else {
//                imageLayer2.contents = imgarray[image+1].cgImage
//                blackLayer.addSublayer(imageLayer2)
//            }
//
//            let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
//            scaleAnimation.values = [0, 1.0, 0]
//            scaleAnimation.beginTime = CFTimeInterval(time[image])
//            scaleAnimation.duration = 3
//            scaleAnimation.isRemovedOnCompletion = false
//            blackLayer.add(scaleAnimation, forKey: "transform.scale")
//
//            let fadeInOutAnimation = CABasicAnimation(keyPath: "opacity")
//            fadeInOutAnimation.fromValue = 1
//            fadeInOutAnimation.toValue = 1
//            fadeInOutAnimation.duration = 3
//            fadeInOutAnimation.beginTime = CFTimeInterval(time[image])
//            fadeInOutAnimation.isRemovedOnCompletion = false
//            blackLayer.add(fadeInOutAnimation, forKey: "opacity")

            ///#10. scale(big->small->big)///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //            blackLayer.opacity = 0
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
            //            scaleAnimation.values = [1, 0, 1]
            //            scaleAnimation.beginTime = CFTimeInterval(time[image])
            //            scaleAnimation.duration = 3
            //            scaleAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(scaleAnimation, forKey: "transform.scale")
            //
            //            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            //            fadeOutAnimation.fromValue = 1
            //            fadeOutAnimation.toValue = 1
            //            fadeOutAnimation.duration = 3
            //            fadeOutAnimation.beginTime = CFTimeInterval(time[image])
            //            fadeOutAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(fadeOutAnimation, forKey: "opacity")

            parentlayer.addSublayer(blackLayer)
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layercomposition.renderSize = size
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = [layerinstruction]
        layercomposition.instructions = [instruction]

        let animatedVideoURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/video2.mp4")
        removeFileAtURLIfExists(url: animatedVideoURL)

        guard let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { return nil }
        assetExport.videoComposition = layercomposition
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = animatedVideoURL as URL
        assetExport.exportAsynchronously(completionHandler: {
            switch assetExport.status {
            case AVAssetExportSession.Status.failed:
                print("failed \(String(describing: assetExport.error))")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(String(describing: assetExport.error))")
            default:
                print("Exported")
            }
        })
        print("--- \(animatedVideoURL.absoluteURL) \(animatedVideoURL) \(animatedVideoURL.isFileURL)")
        return animatedVideoURL.absoluteURL
    }
}

