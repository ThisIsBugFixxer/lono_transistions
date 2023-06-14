//
//  UIImage+Extension.swift
//  lono transistions
//
//  Created by Priyam Mehta on 09/05/23.
//

import Foundation
import UIKit
extension UIImage {
//    var fixedOrientation: UIImage {
//        
//        guard imageOrientation != .up else { return self }
//        
//        var transform: CGAffineTransform = .identity
//        switch imageOrientation {
//        case .down, .downMirrored:
//            transform = transform
//                .translatedBy(x: size.width, y: size.height).rotated(by: .pi)
//        case .left, .leftMirrored:
//            transform = transform
//                .translatedBy(x: size.width, y: 0).rotated(by: .pi)
//        case .right, .rightMirrored:
//            transform = transform
//                .translatedBy(x: 0, y: size.height).rotated(by: -.pi/2)
//        case .upMirrored:
//            transform = transform
//                .translatedBy(x: size.width, y: 0).scaledBy(x: -1, y: 1)
//        default:
//            break
//        }
//        
//        guard
//            let cgImage = cgImage,
//            let colorSpace = cgImage.colorSpace,
//            let context = CGContext(
//                data: nil, width: Int(size.width), height: Int(size.height),
//                bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0,
//                space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue
//            )
//        else { return self }
//        context.concatenate(transform)
//        
//        var rect: CGRect
//        switch imageOrientation {
//        case .left, .leftMirrored, .right, .rightMirrored:
//            rect = CGRect(x: 0, y: 0, width: size.height, height: size.width)
//        default:
//            rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        }
//        
//        context.draw(cgImage, in: rect)
//        return context.makeImage().map { UIImage(cgImage: $0) } ?? self
//    }
//    
//    func cropToBounds(size: CGSize) -> UIImage {
//        
//        let height = size.height
//        let width = size.width
//        
//        let cgimage = self.cgImage!
//        let contextImage: UIImage = UIImage(cgImage: cgimage)
//        let contextSize: CGSize = contextImage.size
//        var posX: CGFloat = 0.0
//        var posY: CGFloat = 0.0
//        var cgwidth: CGFloat = CGFloat(width)
//        var cgheight: CGFloat = CGFloat(height)
//        
//        // See what size is longer and create the center off of that
////        if contextSize.width > contextSize.height {
////            posX = ((contextSize.width - contextSize.height) / 2)
////            posY = 0
////            cgwidth = width
////            cgheight = height
////        } else {
////            posX = 0
////            posY = ((contextSize.height - contextSize.width) / 2)
////            cgwidth = width
////            cgheight = height
////        }
//        
//        if contextSize.width > width {
//            posX = (contextSize.width - width) / 2
//        }else {
//            posX = (width - contextSize.width) / 2
//        }
//
//        if contextSize.height > height {
//            posY = (contextSize.height - height) / 2
//        }else {
//            posY = (height - contextSize.height) / 2
//        }
//
//        cgwidth = width
//        cgheight = height
////        posX = contextSize.width -
//        
//        
//        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
//        
//        // Create bitmap image from context using the rect
//        let imageRef: CGImage = cgimage.cropping(to: rect)!
//        
//        // Create a new image based on the imageRef and rotate back to the original orientation
//        let image: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
//        
//        return image
//    }
//    
//    
//    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
//        let widthRatio = targetSize.width / size.width
//        let heightRatio = targetSize.height / size.height
//        
//        let scaleFactor = min(widthRatio, heightRatio)
//
//        let scaledImageSize = CGSize(
//            width: size.width * scaleFactor,
//            height: size.height * scaleFactor
//        )
//
//        let renderer = UIGraphicsImageRenderer(
//            size: scaledImageSize
//        )
//
//        let scaledImage = renderer.image { _ in
//            self.draw(in: CGRect(
//                origin: .zero,
//                size: scaledImageSize
//            ))
//        }
//        return scaledImage
//    }
//    
//    
//    func resizedCroppedImage(newSize:CGSize) -> UIImage {
//        
//        var ratio: CGFloat = 0
//        var delta: CGFloat = 0
//        var drawRect = CGRect()
//        
//        if newSize.width > newSize.height {
//            
//            ratio = newSize.width / self.size.width
//            delta = (ratio * self.size.height) - newSize.height
//            drawRect = CGRect(x: 0, y: -delta / 2, width: newSize.width, height: newSize.height + delta)
//            
//        } else {
//            
//            ratio = newSize.height / self.size.height
//            delta = (ratio * self.size.width) - newSize.width
//            drawRect = CGRect(x: -delta / 2, y: 0, width: newSize.width + delta, height: newSize.height)
//            
//        }
//        
//        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
//        self.draw(in: drawRect)
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        return newImage ?? UIImage()
//    }
//    
    func scalingAndCropping(for targetSize: CGSize) -> UIImage {
            let sourceImage = self
            var newImage: UIImage? = nil
            let imageSize = sourceImage.size
            let width = imageSize.width
            let height = imageSize.height
            let targetWidth = targetSize.width
            let targetHeight = targetSize.height
            var scaleFactor: CGFloat = 0.0
            var scaledWidth = targetWidth
            var scaledHeight = targetHeight
            var thumbnailPoint = CGPoint(x: 0.0, y: 0.0)

            if !imageSize.equalTo(targetSize) {
                let widthFactor = targetWidth / width
                let heightFactor = targetHeight / height

                if widthFactor > heightFactor {
                    scaleFactor = widthFactor // scale to fit height
                } else {
                    scaleFactor = heightFactor // scale to fit width
                }

                scaledWidth = width * scaleFactor
                scaledHeight = height * scaleFactor

                // center the image
                if widthFactor > heightFactor {
                    thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
                } else {
                    if widthFactor < heightFactor {
                        thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
                    }
                }
            }

            UIGraphicsBeginImageContext(targetSize) // this will crop

            var thumbnailRect = CGRect.zero
            thumbnailRect.origin = thumbnailPoint
            thumbnailRect.size.width = scaledWidth
            thumbnailRect.size.height = scaledHeight

            sourceImage.draw(in: thumbnailRect)

            newImage = UIGraphicsGetImageFromCurrentImageContext()

            if newImage == nil {
                print("could not scale image")
            }

            //pop the context to get back to the default
            UIGraphicsEndImageContext()
        
        return newImage ?? UIImage()
    }
//    
//    //
//    
//    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
//        var width: CGFloat
//        var height: CGFloat
//        var newImage: UIImage
//        
//        let size = self.size
//        let aspectRatio =  size.width/size.height
//        
//        switch contentMode {
//        case .scaleAspectFit:
//            if aspectRatio > 1 {                            // Landscape image
//                width = dimension
//                height = dimension / aspectRatio
//            } else {                                        // Portrait image
//                height = dimension
//                width = dimension * aspectRatio
//            }
//            
//        default:
//            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
//        }
//        
//        if #available(iOS 10.0, *) {
//            let renderFormat = UIGraphicsImageRendererFormat.default()
//            renderFormat.opaque = opaque
//            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
//            newImage = renderer.image {
//                (context) in
//                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
//            }
//        } else {
//            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
//            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
//            newImage = UIGraphicsGetImageFromCurrentImageContext()!
//            UIGraphicsEndImageContext()
//        }
//        
//        return newImage
//    }
//    
//    
//    func newResized(to newSize: CGSize) -> UIImage {
//        return UIGraphicsImageRenderer(size: newSize).image { _ in
//            let hScale = newSize.height / size.height
//            let vScale = newSize.width / size.width
//            let scale = max(hScale, vScale) // scaleToFill
//            let resizeSize = CGSize(width: size.width*scale, height: size.height*scale)
//            var middle = CGPoint.zero
//            if resizeSize.width > newSize.width {
//                middle.x -= (resizeSize.width-newSize.width)/2.0
//            }
//            if resizeSize.height > newSize.height {
//                middle.y -= (resizeSize.height-newSize.height)/2.0
//            }
//            
//            draw(in: CGRect(origin: middle, size: resizeSize))
//        }
//    }
//    
//    func newResized(to newSize: CGSize, opaque: Bool = true, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
//        var width: CGFloat
//        var height: CGFloat
//        var newImage: UIImage
//        
//        let size = self.size
//        let aspectRatio =  size.width/size.height
//        
//        switch contentMode {
//        case .scaleAspectFit:
//            if aspectRatio > 1 {                            // Landscape image
//                width = newSize.width
//                height = newSize.height / aspectRatio
//            } else {                                        // Portrait image
//                height = newSize.height
//                width = newSize.width * aspectRatio
//            }
//            
//        default:
//            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
//        }
//        
//        if #available(iOS 10.0, *) {
//            let renderFormat = UIGraphicsImageRendererFormat.default()
//            renderFormat.opaque = opaque
//            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
//            newImage = renderer.image {
//                (context) in
//                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
//            }
//        } else {
//            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
//            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
//            newImage = UIGraphicsGetImageFromCurrentImageContext()!
//            UIGraphicsEndImageContext()
//        }
//        
//        return newImage
//    }
//    
//    
//    func liaFilter() -> UIImage {
//        let inImage = CIImage(image: self)
//
//        let rgbVector = CIVector(x: 0, y: 1, z: 0, w: 0)
//        let aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
//
//        dynamic let colorMatrix = CIFilter(name: "CIColorMatrix")
//
//        if colorMatrix != nil {
//            colorMatrix?.setDefaults()
//            colorMatrix?.setValue(inImage, forKey: kCIInputImageKey)
//            colorMatrix?.setValue(rgbVector, forKey: "inputRVector")
//            colorMatrix?.setValue(rgbVector, forKey: "inputGVector")
//            colorMatrix?.setValue(rgbVector, forKey: "inputBVector")
//            colorMatrix?.setValue(aVector, forKey: "inputAVector")
//
//            if let output = colorMatrix?.outputImage, let cgImage = CIContext().createCGImage(output, from: output.extent) {
//                return UIImage(cgImage: cgImage)
//            }
//        }
//        return self
//    }
//    
//    
//}
//
//
//extension UIImage {
//    class func imageFromColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1), scale: CGFloat) -> UIImage? {
//        UIGraphicsBeginImageContextWithOptions(size, false, scale)
//        color.setFill()
//        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return image
//    }
//    
//    func resizedImage(for size: CGSize) -> UIImage? {
//            let image = self.cgImage
//            print(size)
//            let context = CGContext(data: nil,
//                                    width: Int(size.width),
//                                    height: Int(size.height),
//                                    bitsPerComponent: image!.bitsPerComponent,
//                                    bytesPerRow: Int(size.width),
//                                    space: image?.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
//                                    bitmapInfo: image!.bitmapInfo.rawValue)
//            context?.interpolationQuality = .high
//            context?.draw(image!, in: CGRect(origin: .zero, size: size))
//
//            guard let scaledImage = context?.makeImage() else { return nil }
//
//            return UIImage(cgImage: scaledImage)
//    }
//    
//    func resizeImage(targetSize: CGSize) -> UIImage {
//        let size = self.size
//        
//        let widthRatio  = targetSize.width  / size.width
//        let heightRatio = targetSize.height / size.height
//        
//        // Figure out what our orientation is, and use that to form the rectangle
//        var newSize: CGSize
//        if(widthRatio > heightRatio) {
//            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
//        } else {
//            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
//        }
//        
//        // This is the rect that we've calculated out and this is what is actually used below
//        let rect = CGRect(origin: .zero, size: newSize)
//        
//        // Actually do the resizing to the rect using the ImageContext stuff
//        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
//        self.draw(in: rect)
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        return newImage ?? self
//    }
//    
//    //    convenience init?(size: CGSize, gradientPoints: [GradientPoint], scale : CGFloat) {
//    //        UIGraphicsBeginImageContextWithOptions(size, false, scale)
//    //
//    //        guard let context = UIGraphicsGetCurrentContext() else { return nil }       // If the size is zero, the context will be nil.
//    //        guard let gradient = CGGradient(colorSpace: CGColorSpaceCreateDeviceRGB(), colorComponents: gradientPoints.compactMap { $0.color.cgColor.components }.flatMap { $0 }, locations: gradientPoints.map { $0.location }, count: gradientPoints.count) else {
//    //            return nil
//    //        }
//    //
//    //        context.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: 0, y: size.height), options: CGGradientDrawingOptions())
//    //        guard let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
//    //        self.init(cgImage: image)
//    //        defer { UIGraphicsEndImageContext() }
//    //    }
//    
//}
//
//
//
//extension UIImage {
//    func withAlphaComponent(_ alpha: CGFloat) -> UIImage? {
//        UIGraphicsBeginImageContextWithOptions(size, false, scale)
//        defer { UIGraphicsEndImageContext() }
//        
//        draw(at: .zero, blendMode: .normal, alpha: alpha)
//        return UIGraphicsGetImageFromCurrentImageContext()
//    }
//}
//
//
//extension Int {
//    func random() -> String {
//        var number = String()
//        for _ in 1...self {
//            number += "\(Int.random(in: 1...9))"
//        }
//        print("Generated Number is \(number)")
//        return number
//    }
//}
//// MARK: - for reduce the Quallity of the Image
//extension UIImage {
//    func resized(withPercentage percentage: CGFloat, isOpaque: Bool = true) -> UIImage? {
//        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
//        let format = imageRendererFormat
//        format.opaque = isOpaque
//        return UIGraphicsImageRenderer(size: canvas, format: format).image {
//            _ in draw(in: CGRect(origin: .zero, size: canvas))
//        }
//    }
//    
//    func compress(to kb: Int, allowedMargin: CGFloat = 0.2) -> Data {
//        let bytes = kb * 1024
//        var compression: CGFloat = 1.0
//        let step: CGFloat = 0.05
//        var holderImage = self
//        var complete = false
//        while(!complete) {
//            if let data = holderImage.jpegData(compressionQuality: 1.0) {
//                let ratio = data.count / bytes
//                if data.count < Int(CGFloat(bytes) * (1 + allowedMargin)) {
//                    complete = true
//                    return data
//                } else {
//                    let multiplier:CGFloat = CGFloat((ratio / 5) + 1)
//                    compression -= (step * multiplier)
//                }
//            }
//            
//            guard let newImage = holderImage.resized(withPercentage: compression) else { break }
//            holderImage = newImage
//        }
//        return Data()
//    }
//    
//
//
}
