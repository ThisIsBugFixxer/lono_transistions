//
//  Animation.swift
//  lono transistions
//
//  Created by Priyam Mehta on 20/02/23.
//


import Foundation
import UIKit
import AVFoundation

// structure -> make 3 functions
// func 1 -> animates the image
// func 2 -> converts those in video and saves it
// func 3 -> video merging (if needed)
// func 4 -> for multiple animations
// enum   -> to handle the diff animations
// func 5 -> to handle the bg of the images (maybe 2 of them, fg and bg) (if only func 1 doesnt do it directly)




class AnimateImages {


    var fgImage = UIImageView()
    var bgImage = UIImageView()
    var frames: Int = 30 // 30 fps
    var duration: Int32 = 2 // seconds

    var image = UIImage()
    var layer = CALayer()
    var animation = CABasicAnimation()


    init() {
        // Set up the CALayer with the image to animate
//        let img = CIImage(image: fgImage.image!)
        let img = CIImage(image: UIImage(named: "img")!) // setting an optional image
        image = UIImage(ciImage: img!)
        layer = CALayer()
        layer.contents = image.cgImage
        layer.bounds = CGRect(x: 0, y: 0, width: image.size.width ?? 0, height: image.size.height ?? 0)

    }





    func animate() -> URL {
        // func 1 -> animates the image

//        let layer (aka mainView) = UIView(frame: CGRect(x: 20, y: 100, width: 140, height: 100))

        animation = CABasicAnimation()
        animation.keyPath = "position.x"
        animation.fromValue = 20 + 140 / 2
        animation.toValue = 300
        animation.duration = 1

        self.fgImage.layer.add(animation, forKey: "basic")
        self.fgImage.layer.position = CGPoint(x: 300, y: 100 + 100 / 2) // update to final position

        return createVideo(image: self.image)

    }

    func animateFadeIn(imageView: UIImageView) {
        imageView.alpha = 0

        animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 1
        animation.fromValue = 0
        animation.toValue = 1

        imageView.layer.add(animation, forKey: "opacity")
    }

    func animateSlideIn(imageView: UIImageView) {
        imageView.layer.position = CGPoint(x: -imageView.frame.width / 2, y: imageView.layer.position.y)

        animation = CABasicAnimation(keyPath: "position")
        animation.duration = 1
        animation.fromValue = NSValue(cgPoint: CGPoint(x: -imageView.frame.width / 2, y: imageView.layer.position.y))
        animation.toValue = NSValue(cgPoint: imageView.layer.position)

        imageView.layer.add(animation, forKey: "position")
    }

    func animateRotate(imageView: UIImageView) {
        animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 1
        animation.fromValue = 0
        animation.toValue = Float.pi * 2

        imageView.layer.add(animation, forKey: "rotation")
    }

    private func createVideo(image: UIImage) -> URL {
        
        // making a name for the image
        let fileName = randomFileNameGenerator()
        
        // Set up the AVAssetWriter
        let videoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).mov")
        let videoSize = CGSize(width: image.size.width , height: image.size.height)
        let videoWriter = try! AVAssetWriter(outputURL: videoURL, fileType: AVFileType.mov)
        let videoSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: NSNumber(value: Float(videoSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(videoSize.height))
        ] as [String: Any]
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: nil)
        videoWriter.add(videoInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: CMTime.zero)

        // Write each frame of the animation to the video file
        let animationDuration = animation.duration
        let frameDuration = CMTimeMake(value: 1, timescale: Int32(animationDuration * 60))
        let frameCount = Int(animationDuration * 60)
        for i in 0 ..< frameCount {
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(i))

            let renderer = UIGraphicsImageRenderer(size: layer.bounds.size)
            let image = renderer.image { ctx in
                layer.render(in: ctx.cgContext)
            }
            

//            let pixelBuffer = image.ciImage?.pixelBuffer
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferCreate(kCFAllocatorDefault,
                                Int(videoSize.width),
                                Int(videoSize.height),
                                kCVPixelFormatType_32BGRA,
                                [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary,
                                &pixelBuffer)
            
            while !videoInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.1)
            }
            pixelBufferAdaptor.append(pixelBuffer!, withPresentationTime: presentationTime)
        }
        
        // Finalize the video file
        videoInput.markAsFinished()
        videoWriter.finishWriting(completionHandler: {
            print("=== Video file created: \(videoURL)")
        })
        
        return videoURL
    }

    private func randomFileNameGenerator() -> String {
        let currentDateTime = Date()

        // initialize the date formatter and set the style
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short

        // get the date time String from the date object
        return "\(formatter.string(from: currentDateTime))_\(Int.random(in: 0 ..< 10000))" // "10/8/16, 10:52 PM"
    }
}

