//
//  MutualFriendsCell.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class MutualFriendsCell: UITableViewCell {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var label: UILabel!
    
    var mutualFriendsInfo:[[NSObject:AnyObject]]? = nil {
        didSet {
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if mutualFriendsInfo != nil {
            self.populateScrollView()
            let count = mutualFriendsInfo!.count
            if count > 1 {
                label.text = String(format: NSLocalizedString("%d common friends", comment:""), count)
            }
            else {
                label.text = NSLocalizedString("1 common friend", comment: "")
            }
        }
    }
    
    func populateScrollView() {
        
        let radius:CGFloat = 40
        let verticalSpacing:CGFloat = 0
        
        var idx:Int = 0
        for user in mutualFriendsInfo! {
            let pageIndex = CGFloat((idx - (idx % 3))/3)
            let name = user["name"] as! String
            let fbid = user["id"] as! String
            
            let t = CGFloat(idx % 3)
            let s = 0.3125*t + 0.1875
            let xCenter = s * self.frame.width + (pageIndex * self.frame.width)
            
            let x:CGFloat = xCenter - radius
            let y:CGFloat = 0.0
            
            let pView = PictureView(frame: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
            pView.tag = idx
            pView.userId = fbid
            pView.layer.cornerRadius = radius
            
            scrollView.addSubview(pView)
            
            let w_3 = (self.frame.width - 20) / 3
            let h = scrollView.frame.height - (2*radius) - verticalSpacing
            let labelY = (2*radius) + verticalSpacing
            let labelFrame = CGRect(x: 0, y: labelY, width: w_3, height: h)
            let label = UILabel(frame: labelFrame)
            label.center.x = pView.center.x
            label.numberOfLines = 0
            label.font = UIFont(name: "Montserrat-Regular", size: 16.0)!
            label.textAlignment = .Center
            label.textColor = UIColor(hue: 0.6, saturation: 0.2, brightness: 0.5, alpha: 1.0)
            label.text = name
            
            scrollView.addSubview(label)
            idx += 1
        }
        
        let w_3 = self.frame.width / 3
        scrollView.contentSize = CGSizeMake(CGFloat(idx) * w_3, scrollView.frame.height)
    }
    
    
}
