//
//  ZLPhotographerTool.swift
//  ZLPhotographerDemo
//
//  Created by 朱子澜 on 16/12/23.
//  Copyright © 2016年 杉玉府. All rights reserved.
//

import UIKit
import Photos
import CoreGraphics

struct ZLPhotographerTool {
    
    // todo: use image operation queue
    typealias ImageOperation = (() -> Void)
    static var imageOperationQueue: DispatchQueue = DispatchQueue(label: "ZLPhotoEditor.ImageOperation")
    
    static func enqueueImageOperation(_ operation: @escaping ImageOperation) {
        operation()
    }
    
}



// MARK: - File

extension ZLPhotographerTool {
    
    static func saveToAlbum(image: UIImage?, completion: ((Bool, String?) -> Swift.Void)?) {
        guard let image = image else {
            completion?(false, nil)
            return
        }
        
        var localIdentifier: String? = nil
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
        }) { (complete, error) in
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(complete, localIdentifier)
                }
            }
        }
    }
}



// MARK: - Image

extension ZLPhotographerTool {
    
    static func resize(image: UIImage, to size: CGSize) -> UIImage {
        let w = floor(size.width)
        let h = floor(size.height)
        UIGraphicsBeginImageContext(CGSize(width: w, height: h))
        image.draw(in: CGRect(x: 0, y: 0, width: w, height: h))
        let newImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImg ?? image
    }
    
    static func getAutoFilteredImage(from image: UIImage, context: CIContext? = nil) -> UIImage {
        guard var inputImage = CIImage(image: image) else {
            return image
        }
        
        let filters = inputImage.autoAdjustmentFilters()
        if filters.count == 0 {
            return image
        }
        
        for filter in filters {
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            inputImage = filter.outputImage ?? inputImage
        }
        
        let context = context ?? CIContext()
        guard let imageRef = context.createCGImage(inputImage, from: inputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: imageRef)
    }
    
    static func getFilteredImage(from image: UIImage, filterName: String, context: CIContext? = nil) -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            return image
        }
        
        guard let filter = CIFilter(name: filterName) else {
            return image
        }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else {
            return image
        }
        
        let context = context ?? CIContext()
        guard let imageRef = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: imageRef)
    }
    
    static func fixedOrientationImage(from image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let fixedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return fixedImage ?? image
    }
    
    static func generatePixellateImage(from image: UIImage, level: Int, boundingRect: CGRect? = nil, completion: ((UIImage?) -> Swift.Void)?) {
        ZLPhotographerTool.imageOperationQueue.async {
            let pixellatedImage = ZLPhotographerTool.doGeneratePixellateImage(from: image, level: level, boundingRect: boundingRect)
            DispatchQueue.main.async {
                completion?(pixellatedImage)
            }
        }
    }
    
    private static func doGeneratePixellateImage(from image: UIImage, level: Int, boundingRect: CGRect? = nil) -> UIImage? {
        let kBitsPerComponent = 8
        let kBitsPerPixel = 32
        let kPixelChannelCount = 4
        
        let colorspace = CGColorSpaceCreateDeviceRGB()
        guard let imageRef = image.cgImage else {
            ldb("failed to get image ref.")
            return nil
        }
        
        let width = imageRef.width
        let height = imageRef.height
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let orientation = image.imageOrientation
        
        var realRect: (x: Int, y: Int, width: Int, height: Int) = (x: 0, y: 0, width: 0, height: 0)
        if let boundingRect = boundingRect {
            let _x = Int(boundingRect.origin.x)
            let _y = Int(boundingRect.origin.y)
            let _w = Int(boundingRect.size.width)
            let _h = Int(boundingRect.size.height)
            switch orientation {
            case .up:
                realRect = (x: _x, y: _y, width: _w, height: _h)
            case .upMirrored:
                realRect = (x: _w - _x, y: _y, width: _w, height: _h)
            case .down:
                realRect = (x: _x, y: _h - _y, width: _w, height: _h)
            case .downMirrored:
                realRect = (x: _w - _x, y: _h - _y, width: _w, height: _h)
            case .left:
                realRect = (x: _y, y: _w - _x, width: _h, height: _w)
            case .leftMirrored:
                realRect = (x: _y, y: _x, width: _h, height: _w)
            case .right:
                realRect = (x: _h - _y, y: _x, width: _h, height: _w)
            case .rightMirrored:
                realRect = (x: _h - _y, y: _w - _x, width: _h, height: _w)
            }
        } else {
            realRect = (x: 0, y: 0, width: width, height: height)
        }
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: kBitsPerComponent, bytesPerRow: width*kPixelChannelCount, space: colorspace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            ldb("failed to create input context.")
            return nil
        }
        context.draw(imageRef, in: rect)
        guard let bitmapData = context.data else {
            ldb("failed to get context data.")
            return nil
        }
        
        let pixels: UnsafeMutableRawPointer = bitmapData
        var index: Int = 0
        var preIndex: Int = 0
        
        for x in realRect.y..<(realRect.y + realRect.height - 1) {
            for y in realRect.x..<(realRect.x + realRect.width - 1) {
                index = x * width + y
                if (x%level == 0) {
                    if (y%level == 0) {
                        memcpy(pixels, bitmapData + kPixelChannelCount * index, kPixelChannelCount)
                    } else {
                        memcpy(bitmapData + kPixelChannelCount * index, pixels, kPixelChannelCount)
                    }
                } else {
                    preIndex = (x - 1) * width + y
                    memcpy(bitmapData + kPixelChannelCount*index, bitmapData + kPixelChannelCount * preIndex, kPixelChannelCount);
                }
            }
        }
        
        let dataLength = width * height * kPixelChannelCount
        let unwrappedProvider = CGDataProvider(dataInfo: nil, data: bitmapData, size: dataLength) { (p1, p2, i) in
            // provider release callback.
        }
        
        guard let provider = unwrappedProvider else {
            ldb("nil provider")
            return nil
        }
        
        guard let pixellatedImageRef = CGImage(width: width, height: height, bitsPerComponent: kBitsPerComponent, bitsPerPixel: kBitsPerPixel, bytesPerRow: width*kPixelChannelCount, space: colorspace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent) else {
            ldb("failed to create pixellated image ref.")
            return nil
        }
        
        guard let outputContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: kBitsPerComponent, bytesPerRow: width*kPixelChannelCount, space: colorspace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            ldb("failed to create output context.")
            return nil
        }
        
        outputContext.draw(pixellatedImageRef, in: rect)
        guard let resultImageRef = outputContext.makeImage() else {
            ldb("failed to create result image ref.")
            return nil
        }
        
        let resultImage = UIImage(cgImage: resultImageRef, scale: 1.0, orientation: orientation)
        return resultImage
    }
}
