//
//  BlurvDropView.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

protocol BlurvDropViewDelegate {
    func dropViewDidChangeDirection(direction:Int)
    func dropViewDidGetTapped(dropView:BlurvDropView)
    func dropViewDidStartAnimating(dropView:BlurvDropView)
    func dropViewDidStopAnimating(dropView:BlurvDropView)
}

class BlurvDropView:UIView, UIGestureRecognizerDelegate {
    
    let mask = UIImage(named: "drop_loading")!
    
    private var stop:Bool = false
    private var fillPercent:CGFloat = 0.0
    private var fillPercentIncrement:CGFloat = 0.01
    private var direction:Int = 1 {
        didSet {
            if direction != oldValue {
                self.delegate?.dropViewDidChangeDirection(self.direction)
                if stop && direction == 1 {
                    self.delegate?.dropViewDidStopAnimating(self)
                    displayLink.paused = true
                    stop = false
                    animating = false
                }
            }
        }
    }
    
    private(set) var animating:Bool = false
    
    
    let empty_color = UIColor(white: 0.88, alpha: 1.0).CGColor
    let fill_color_start = UIColor(red: 0.678, green: 0, blue: 0.341, alpha: 1.0).CGColor
    let fill_color_end = UIColor(red: 0.784, green: 0.427, blue: 0.843, alpha: 1.0).CGColor
    
    lazy var gradient:CGGradientRef = {
        let colors:[CFTypeRef] = [self.fill_color_end, self.fill_color_start]
        var colorsPointer = UnsafeMutablePointer<UnsafePointer<Void>>(colors)
        var colorsCFArray = CFArrayCreate(nil, colorsPointer, colors.count, nil)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        return CGGradientCreateWithColors(colorSpace, colorsCFArray, nil)!
    }()
    
    
    var rect:CGRect {
        let x = self.bounds.width / 2 - mask.size.width / 2
        let y = self.bounds.height / 2 - mask.size.height / 2
        let w = mask.size.width
        let h = mask.size.height
        
        return CGRectMake(x, y, w, h)
    }
    
    var delegate:BlurvDropViewDelegate?
    
    var displayLink:CADisplayLink!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    func reset() {
        self.stopAnimating()
        self.fillPercent = 0
        self.direction = 1
        self.setNeedsDisplay()
    }
    
    func setup() {
        self.backgroundColor = UIColor.clearColor()
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(BlurvDropView.handleTap))
        tapGR.delegate = self
        self.addGestureRecognizer(tapGR)
        
        displayLink = CADisplayLink(target: self, selector: #selector(BlurvDropView.updateFillPercent))
        displayLink.paused = true
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func handleTap() {
        self.delegate?.dropViewDidGetTapped(self)
    }
    
    func startAnimating() {
        animating = true
        displayLink.paused = false
        self.delegate?.dropViewDidStartAnimating(self)
    }
    func stopAnimating() {
        stop = true
    }
    
    func updateFillPercent() {
        fillPercent += fillPercentIncrement * CGFloat(direction)
        if fillPercent >= 1 { direction = -1; fillPercent = 1; }
        else if fillPercent <= 0 { direction = 1; fillPercent = 0 }
        self.setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetAllowsAntialiasing(context, true)
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        CGContextTranslateCTM(context, 0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        let w = self.rect.size.width
        let h = self.rect.size.height
        let x = self.rect.origin.x
        let y = self.rect.origin.y
        
        let top = CGRectMake(x, y, w, h*(fillPercent))
        let bottom = CGRectMake(x, y+h*(fillPercent), w, h*(1-fillPercent))
        
        let start = CGPointMake(0, y)
        let end = CGPointMake(0, y+h*(fillPercent))
        
        CGContextSetFillColorWithColor(context, empty_color)
        CGContextClipToMask(context, self.rect, mask.CGImage)
        CGContextFillRect(context, bottom)
        
        CGContextClipToRect(context, top)
        CGContextDrawLinearGradient(context, gradient, start, end, CGGradientDrawingOptions())
        
    }
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}










