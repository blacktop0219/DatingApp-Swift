//
//  ChatCell.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-02.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit


class ChatCell: UITableViewCell {

    @IBOutlet weak var topSeparator: UIView!
    @IBOutlet weak var bottomSeparator: UIView!
    
    @IBOutlet weak var pictureView: PictureView!
    @IBOutlet weak var notificationView: CustomView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    
    var isFirst:Bool = false {
        didSet {
            topSeparator.hidden = !isFirst
        }
    }
    var hasNotification:Bool = false {
        didSet {
            notificationView.hidden = !hasNotification
            descriptionLabel.font = hasNotification ? UIFont(name: "Montserrat-Bold", size: 14.0)!:UIFont(name: "Montserrat-Regular", size: 14.0)!
        }
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.selectionStyle = .None
        self.pictureView.userInteractionEnabled = false
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let animations = {
            if selected {
                self.backgroundColor = CELL_SELECTED_BG_COLOR_SECONDARY
            }
            else {
                self.backgroundColor = CELL_DEFAULT_BG_COLOR
            }
        }
        
        if animated {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                animations()
            })
        }
        else {
            animations()
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        let animations = {
            if highlighted {
                self.backgroundColor = CELL_SELECTED_BG_COLOR_SECONDARY
            }
            else {
                self.backgroundColor = CELL_DEFAULT_BG_COLOR
            }
        }
        
        if animated {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                animations()
            })
        }
        else {
            animations()
        }
    }
    
    
    func setNotificationRead() {
        self.hasNotification = false
    }

}
