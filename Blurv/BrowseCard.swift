//
//  BrowseCard.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class BrowseCard: CustomView {

    let infoLabelFont = UIFont(name: "Montserrat-Regular", size: 16.0)!
    let infoLabelFont_bold = UIFont(name: "Montserrat-Regular", size: 16.0)!
    
    let infoLabelColor = UIColor(hue: 217/360, saturation: 0.2, brightness: 0.5, alpha: 1.0)
    
    let info_top_margin:CGFloat = 30.0
    let info_bottom_margin:CGFloat = 15.0
    let info_left_margin:CGFloat = 15.0
    let info_right_margin:CGFloat = 15.0
    let info_icon_trailing:CGFloat = 10.0
    let info_vertical_spacing:CGFloat = 12.0
    let info_icon_estimated_width:CGFloat = 12.0
    let info_icon_y_offset:CGFloat = 3.0
    
    
    var loaded = false
    
    var feedUser:FeedUser! {
        didSet {
            let user = feedUser.user
            //let picture = feedUser.picture
            
            
            nameLabel.text = user.firstName.uppercaseString
            if let age = user.age {
                ageLabel.text = "\(age)"
            }
            
            distanceLabel.text = String(format: NSLocalizedString("%@ away", comment:""), user.localizedDistanceFromCurrentLocation())
            let descriptor = user.isMale ? NSLocalizedString("Active_Male", comment: "male"):NSLocalizedString("Active_Female", comment: "female")
            lastActiveLabel.text = "\(descriptor) \(user.lastActivity.timeAgo())"
            
            //self.pictureView.image = picture.blurred() //blurImage(30, vibrance: 0) //picture.applyBlurWithRadius(30, tintColor: nil, saturationDeltaFactor: 1.0)
            
            // Mutual Friends
            user.getMutualFriendsCount { (count) -> Void in
                if count != 0 {
                    self.mutualFriendsLabel.hidden = false
                    self.mutualFriendsIcon.hidden = false
                    self.mutualFriendsLabel.text = String(count)
                }
                else {
                    self.mutualFriendsLabel.hidden = true
                    self.mutualFriendsIcon.hidden = true
                }
            }
            
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var lastActiveLabel: UILabel!
    @IBOutlet weak var mutualFriendsLabel: UILabel!
    @IBOutlet weak var mutualFriendsIcon: UIImageView!
    
    @IBOutlet weak var pictureView: UIImageView!
    
    @IBOutlet weak var bottomContainer: CustomView!

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if feedUser != nil {
            self.loadBottomInfo()
        }
    }
    
    func loadBottomInfo() {
        
        if loaded { return }
        
        if bottomContainer.subviews.count > 0 {
            for view in bottomContainer.subviews {
                view.removeFromSuperview()
            }
        }
        
        let full_height = bottomContainer.bounds.height - info_top_margin
        let max_width = self.bounds.width - (info_left_margin + info_icon_estimated_width + info_icon_trailing + info_right_margin)
        
        var fullInfo = feedUser.user.mainInfo()
        fullInfo.appendContentsOf(feedUser.user.secondaryInfo())
        fullInfo.appendContentsOf(feedUser.user.ternaryInfo())
        
        var idx = 0
        var currentY = info_top_margin
        for item in fullInfo {
            let font = item.0 == .LookingFor ? infoLabelFont_bold:infoLabelFont

            let labelHeight = heightForLabel(item.1, font: font, width: max_width)
            
            var futureY = currentY + labelHeight
            
            if idx == fullInfo.count - 1 { futureY += info_bottom_margin }
            else { futureY += 12.0 }
            
            if futureY < full_height {
                // Create the stuff
                
                let label_x = info_left_margin + info_icon_estimated_width + info_icon_trailing
                let labelFrame = CGRectIntegral(CGRectMake(label_x, currentY, max_width, labelHeight))
                
                let iconView = UIImageView(image: item.0.icon(false))
                var iconFrame = iconView.frame
                iconFrame.origin.y = labelFrame.origin.y + info_icon_y_offset
                iconFrame.origin.x = info_left_margin
                iconView.frame = CGRectIntegral(iconFrame)
                
                let label = UILabel(frame: labelFrame)
                label.textColor = infoLabelColor
                label.numberOfLines = 0
                label.lineBreakMode = .ByWordWrapping
                label.text = item.1
                label.font = font
                
                bottomContainer.addSubview(iconView)
                bottomContainer.addSubview(label)
                
                currentY = futureY
                
                //self.layoutIfNeeded()
                idx += 1
            }
            else {
                break
            }
        }
        
        loaded = true
    }
    
    func heightForLabel(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
}
