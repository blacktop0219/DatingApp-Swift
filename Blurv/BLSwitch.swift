//
//  BLSwitch.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-22.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

enum MessageMode:Int {
    case Blurvs, Chats
}


let thumb_inset:CGFloat = 2
let thumb_ratio:CGFloat = 0.7
let icon_ratio:CGFloat = 0.16

let threshold_velocity:CGFloat = 500

class BLSwitch: UIControl {
    
    let leftImageView = UIImageView(image: UIImage(named: "lock_icon")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate))
    let rightImageView = UIImageView(image: UIImage(named: "chat_icon")!.imageWithRenderingMode(.AlwaysTemplate))
    
    let labelColor = UIColor(hue: 0.96, saturation: 0.89, brightness: 0.84, alpha: 1)
    var thumb:UIView!
    var thumbLabel:UILabel!
    
    var selectedMode:MessageMode = .Blurvs
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        configureGestureRecognizers()
        configureBackground()
        configureImages()
        configureThumb()
        setFrames()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configureGestureRecognizers()
        configureBackground()
        configureImages()
        configureThumb()
        setFrames()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setFrames()
    }
    private func configureBackground() {
        //self.backgroundColor = UIColor(hue: 240/360, saturation: 0.02, brightness: 0.96, alpha: 1.0)
        self.backgroundColor = UIColor(hue: 0.96, saturation: 0.89, brightness: 0.84, alpha: 1.0)
        self.layer.cornerRadius = self.bounds.height / 2
    }
    private func configureThumb() {
        let x = thumb_inset
        let y = thumb_inset
        let w = (thumb_ratio*self.frame.width) - (2*thumb_inset)
        let h = self.frame.height - (2*thumb_inset)
        let frame = CGRect(x: x, y: y, width: w, height: h)
        thumb = UIView(frame: frame)
        thumb.layer.cornerRadius = frame.height / 2
        thumb.backgroundColor = UIColor.whiteColor()
        
        let labelFrame = CGRectMake(0, 0, frame.width, frame.height)
        thumbLabel = UILabel(frame: labelFrame)
        thumbLabel.text = "Sessions"
        thumbLabel.font = UIFont(name: "Montserrat-Regular", size: 17.0)
        thumbLabel.textAlignment = .Center
        thumbLabel.textColor = self.labelColor
        
        thumb.addSubview(thumbLabel)
        
        self.addSubview(thumb)
    }
    private func configureImages() {
        //let tint = UIColor(hue: 217/360, saturation: 0.2, brightness: 0.5, alpha: 0.2)
        let tint = UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 1)
        leftImageView.tintColor = tint
        rightImageView.tintColor = tint
        
        self.addSubview(leftImageView)
        self.addSubview(rightImageView)
    }
    private func configureGestureRecognizers() {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(BLSwitch.handleTap(_:)))
        self.addGestureRecognizer(tapGR)
        
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(BLSwitch.handlePan(_:)))
        self.addGestureRecognizer(panGR)
    }
    private func setFrames() {
        let l_X = ((icon_ratio)*self.bounds.width) - (leftImageView.bounds.width / 2)
        let l_Y = (self.bounds.height / 2) - (leftImageView.bounds.height / 2)
        
        let r_X = ((1-icon_ratio)*self.bounds.width) - (rightImageView.bounds.width / 2)
        let r_Y = (self.bounds.height / 2) - (rightImageView.bounds.height / 2)
        
        var l_frame = leftImageView.frame
        l_frame.origin.x = l_X
        l_frame.origin.y = l_Y
        
        var r_frame = rightImageView.frame
        r_frame.origin.x = r_X
        r_frame.origin.y = r_Y
        
        leftImageView.frame = l_frame
        rightImageView.frame = r_frame
    }
    
    func setHasGameNotification(hasNotification:Bool) {
        if hasNotification {
            leftImageView.tintColor = blurv_color
        }
        else {
            leftImageView.tintColor = UIColor(hue: 344/360, saturation: 0.9, brightness: 0.588, alpha: 1.0)
        }
    }
    
    func setHasChatNotification(hasNotification:Bool) {
        if hasNotification {
            rightImageView.tintColor = blurv_color
        }
        else {
            rightImageView.tintColor = UIColor(hue: 344/360, saturation: 0.9, brightness: 0.588, alpha: 1.0)
        }
    }
    
    func setSelectedMode(mode:MessageMode, animated:Bool) {
        
        let animations = {
            if mode == .Blurvs {
                var frame = self.thumb.frame
                frame.origin.x = thumb_inset
                self.thumb.frame = frame
            }
            else {
                var frame = self.thumb.frame
                frame.origin.x = self.frame.width - self.thumb.frame.width - thumb_inset
                self.thumb.frame = frame
            }
        }
        
        if animated {
            if self.selectedMode != mode {
                self.selectedMode = mode
                self.sendActionsForControlEvents(.ValueChanged)
            }
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.7, options: .BeginFromCurrentState, animations: { () -> Void in
                animations()
                //self.thumbLabel.alpha = 0
                }, completion: nil)
            
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                self.thumbLabel.alpha = 0
                }, completion: { (complete:Bool) -> Void in
                    self.thumbLabel.text = mode == .Blurvs ? "Sessions":NSLocalizedString("Chat room", comment: "BLSwitch")
                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                        self.thumbLabel.alpha = 1
                    })
            })
            

        }
        else {
            animations()
            self.thumbLabel.text = mode == .Blurvs ? "Sessions":NSLocalizedString("Chat room", comment: "BLSwitch")
            selectedMode = mode
            sendActionsForControlEvents(.ValueChanged)
        }
    }
    
    
    func handleTap(sender:UITapGestureRecognizer) {
        if selectedMode == .Blurvs {
            setSelectedMode(.Chats, animated: true)
        }
        else {
            setSelectedMode(.Blurvs, animated: true)
        }
    }
    func handlePan(sender:UIPanGestureRecognizer) {
        let tX = sender.translationInView(self).x
        let vX = sender.velocityInView(self).x
        
        switch sender.state {
        case .Began, .Changed:
            let oldX = thumb.frame.origin.x
            var x = oldX + tX
            if x < thumb_inset { x = thumb_inset }
            else if x > self.frame.width - self.thumb.frame.width - thumb_inset { x = self.frame.width - self.thumb.frame.width - thumb_inset }
            var newFrame = thumb.frame
            newFrame.origin.x = x
            thumb.frame = newFrame
            sender.setTranslation(CGPointZero, inView: self)
        case .Ended, .Cancelled, .Failed:
            if vX < -threshold_velocity {
                setSelectedMode(.Blurvs, animated: true)
            }
            else if vX > threshold_velocity {
                setSelectedMode(.Chats, animated: true)
            }
            else {
                let xMin = thumb_inset
                let xMax = self.frame.width - self.thumb.frame.width - thumb_inset
                let x = thumb.frame.origin.x
                
                let r = x/(xMax - xMin)
                if r < 0.5 {
                    setSelectedMode(.Blurvs, animated: true)
                }
                else {
                    setSelectedMode(.Chats, animated: true)
                }
            }
        default:
            break
        }
    }
    
}












