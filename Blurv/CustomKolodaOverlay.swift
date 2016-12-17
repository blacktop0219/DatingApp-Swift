//
//  CustomKolodaOverlay.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-29.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Koloda

class CustomKolodaOverlay: OverlayView {
    
    let margin:CGFloat = 10
    let overlayWidth:CGFloat = 145
    let overlayHeight:CGFloat = 87
    
    var overlayImageView:UIImageView!
    
    override var overlayState:SwipeResultDirection?  {
        didSet {
            if overlayState != nil {
                switch overlayState! {
                case .Left :
                    let x = bounds.width - margin - overlayWidth
                    let y = margin
                    self.overlayImageView.frame = CGRectMake(x, y, overlayWidth, overlayHeight)
                    overlayImageView.image = UIImage(named: "overlay_no")
                case .Right :
                    self.overlayImageView.frame = CGRectMake(margin, margin, overlayWidth, overlayHeight)
                    overlayImageView.image = UIImage(named: "overlay_yes")
                default:
                    overlayImageView.image = nil
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    

    
    func setup() {
        self.overlayImageView = UIImageView(frame: CGRectMake(margin, margin, overlayWidth, overlayHeight))
        self.overlayImageView.image = nil
        self.addSubview(overlayImageView)
    }

}


