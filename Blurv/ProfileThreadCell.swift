//
//  ProfileThreadCell.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-22.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class ProfileThreadCell: UITableViewCell {

    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var topThread: UIView!
    @IBOutlet weak var bottomThread: UIView!
    
    @IBOutlet weak var topSeparator: UIView!
    @IBOutlet weak var bottomSeparator: UIView!
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    var content:String! {
        didSet {
            contentLabel.text = content
        }
    }
    var fieldType:ProfileInfoType! {
        didSet {
            self.iconImageView.image = fieldType.icon(true)
            contentLabel.font = UIFont(name: "Montserrat-Regular", size: 15.0)!
/*
            if fieldType == .Language {
                contentLabel.font = UIFont(name: "Montserrat-Bold", size: 15.0)!
            }
            else {
                contentLabel.font = UIFont(name: "Montserrat-Regular", size: 15.0)!
            }
 */
        }
    }
    var isFirst:Bool = false {
        didSet {
            if isFirst {
                topSeparator.hidden = false
                topConstraint.constant = 20
                self.layoutIfNeeded()
                topThread.hidden = isFirst
            }
            else {
                topSeparator.hidden = true
                topConstraint.constant = 6
                self.layoutIfNeeded()
                topThread.hidden = isFirst
            }
        }
    }
    var isLast:Bool = false {
        didSet {
            if isLast {
                bottomSeparator.hidden = false
                bottomConstraint.constant = 12
                self.layoutIfNeeded()
                bottomThread.hidden = isLast
            }
            else {
                bottomSeparator.hidden = true
                bottomConstraint.constant = 4
                self.layoutIfNeeded()
                bottomThread.hidden = isLast
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
