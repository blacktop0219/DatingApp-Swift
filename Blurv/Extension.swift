//
//  Extension.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//
import Foundation
import UIKit

extension Int {
    static func randRange (lower: Int , upper: Int) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower + 1)))
    }
}


extension UIImage {
    
    func resizeToMaxDimension(maxDimension:CGFloat) -> UIImage {

        let currentHeight = self.size.height, currentWidth = self.size.width
        
        var factor:CGFloat! = nil
        
        if currentWidth > currentHeight {
            factor = maxDimension / currentHeight
        }
        else {
            factor = maxDimension / currentWidth
        }
        if factor >= 1 { return self }
        
        let newSize = CGSizeApplyAffineTransform(self.size, CGAffineTransformMakeScale(factor, factor))
        
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, scale)
        self.drawInRect(CGRect(origin: CGPointZero, size: newSize))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    func blurImageWithRadius(blurRadius:CGFloat) -> UIImage {
        
       /* let context = CIContext(options: nil)
        let coreImage = CoreImage.CIImage(image: self)!
        
        let transform = CGAffineTransformIdentity
        let clampFilter = CIFilter(name: "CIAffineClamp")!
        
        
        /// EXTEND EDGES TO AVOID EDGE FADING BECAUSE OF THE BLUR
        let val = NSValue(CGAffineTransform: transform)
        clampFilter.setValue(val, forKey: "inputTransform")
        clampFilter.setValue(coreImage, forKey: "inputImage")
        
        /// BLUR
        
        let blurFilter = CIFilter(name: "CIGaussianBlur")!
        blurFilter.setValue(clampFilter.outputImage, forKey: "inputImage")
        blurFilter.setValue(NSNumber(float: Float(blurRadius)), forKey: "inputRadius")
        
        
        // create image
        let cgImage = context.createCGImage(blurFilter.outputImage!, fromRect: coreImage.extent)
        
       // return UIImage(CGImage: cgImage)*/
        return self
        
    }
    

    func blurRadius() -> CGFloat {
        let height = self.size.height
        let width = self.size.width
        let factor = sqrt(height + width)
        let radius = round(factor * 0.6)
        return radius
    }
    func blurred() -> UIImage {
        return self.blurImageWithRadius(self.blurRadius())
        //return self.applyBlurWithRadius(self.blurRadius(), tintColor: nil, saturationDeltaFactor: 1.0)!
    }
    func blurredForDisplaySize(size:CGSize) -> UIImage {
        let maxDimension = size.width > size.height ? size.width:size.height
        let resized = self.resizeToMaxDimension(maxDimension)
        return resized.blurred()
    }
}



extension String {
    func firstLetterIsVowel() -> Bool {
        if self.characters.count < 1 {
            return false
        }
        else {
            let firstChar = self.substringToIndex(self.startIndex.advancedBy(1)).lowercaseString
            switch firstChar {
                case "a", "e", "i", "o", "u":
                return true
            default:
                return false
            }
        }
    }
}

extension NSDate {
    
    func timeAgo() -> String {
        let interval = fabs(self.timeIntervalSinceNow)
        
        let lang = BlurvClient.languageShortCode()
        if lang == "fr" {
            if interval < 5 {
                return "il y a un instant"
            }
            if interval < 60 {
                return "il y a \(Int(interval)) sec"
            }
            if interval < 60*60 {
                return "il y a \(Int(interval / 60)) min"
            }
            if interval < 24*60*60 {
                let hours = Int(interval / (60*60))
                if hours > 1 { return "il y a \(hours) heures" }
                else { return "il y a une heure" }
            }
            if interval < 7*24*60*60 {
                let days = Int(interval / (24*60*60))
                if days > 1 { return "il y a \(days) jours" }
                else { return "il y a un jour" }
            }
            if interval < 4.33*7*24*60*60 {
                let weeks = Int(interval / (7*24*60*60))
                if weeks > 1 { return "il y a \(weeks) semaines" }
                else { return "il y a une semaine" }
            }
            
            let months = Int(interval / (4.34*24*60*60))
            if months > 1 {
                return "il y a \(months) mois"
            }
            else {
                return "il y a un mois"
            }
        }
        else {
            if interval < 5 {
                return "just now"
            }
            if interval < 60 {
                return "\(Int(interval)) sec ago"
            }
            if interval < 60*60 {
                return "\(Int(interval / 60)) min ago"
            }
            if interval < 24*60*60 {
                let hours = Int(interval / (60*60))
                if hours > 1 { return "\(hours) hours ago" }
                else { return "an hour ago" }
            }
            if interval < 7*24*60*60 {
                let days = Int(interval / (24*60*60))
                if days > 1 { return "\(days) days ago" }
                else { return "one day ago" }
            }
            if interval < 4.33*7*24*60*60 {
                let weeks = Int(interval / (7*24*60*60))
                if weeks > 1 { return "\(weeks) weeks ago" }
                else { return "one week ago" }
            }
            
            let months = Int(interval / (4.34*24*60*60))
            if months > 1 {
                return "\(months) months ago"
            }
            else {
                return "one month ago"
            }
        }
    }
}