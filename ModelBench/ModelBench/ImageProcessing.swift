//
//  MockedImage.swift
//  ModelBench
//
//  Created by kdk on 12/9/24.
//

// ImageProcessing.swift

import UIKit
import CoreVideo


func preprocessImageForEncoder(image: UIImage) -> CVPixelBuffer? {
    guard let resizedImage = resizeImageTo256x256(image: image) else {
        return nil
    }
    return convertToPixelBuffer(from: resizedImage)
}

private func resizeImageTo256x256(image: UIImage) -> UIImage? {
    let size = CGSize(width: 256, height: 256)
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: size))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resizedImage
}

private func convertToPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
    let width = 256
    let height = 256
    var pixelBuffer: CVPixelBuffer?
    let attrs = [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true
    ] as CFDictionary
    let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                     kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
        return nil
    }
    
    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    let pixelData = CVPixelBufferGetBaseAddress(buffer)
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: pixelData, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                  space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        return nil
    }
    
    if let cgImage = image.cgImage {
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
    return buffer
}

