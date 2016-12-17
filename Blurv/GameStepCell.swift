//
//  QuestionCell.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit


class GameStepCell: UITableViewCell {
    
    @IBOutlet weak var bottomThread: UIView!
    @IBOutlet weak var topThread: UIView!
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var status:QuestionStatus = .Locked
    
    var animating:Bool = false
    
    var isFirst:Bool = false {
        didSet {
            topThread.hidden = isFirst
        }
    }
    var isLast:Bool = false {
        didSet {
            bottomThread.hidden = isLast
        }
    }
    
    private func imageNameForStatus(status:QuestionStatus) -> String {
        switch status {
        case .Locked:
            return "question_locked"
        case .Incomplete:
            return "question_incomplete"
        case .Complete:
            return "question_answered"
        default:
            return "question_incomplete"
        }
    }
    
    func setStatus(newStatus:QuestionStatus, animated:Bool, withDelay delay:NSTimeInterval) {
        if imageNameForStatus(status) != imageNameForStatus(newStatus) {
            let newImage = UIImage(named: imageNameForStatus(newStatus))!
            swapIconAnimated(newImage, animated: animated, delay: delay)
            self.status = newStatus
        }
    }
    
    func swapIconAnimated(newImage:UIImage, animated:Bool, delay:NSTimeInterval) {
        if animating {
            return
        }
        if animated {
            animating = true
            UIView.animateWithDuration(0.2, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.iconImageView.transform = CGAffineTransformMakeScale(0.15, 0.15)
                }, completion: { (complete:Bool) in
                    self.iconImageView.image = newImage
                    UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.5, options: .CurveLinear, animations: { 
                        self.iconImageView.transform = CGAffineTransformIdentity
                        }, completion: { (complete:Bool) in
                            self.animating = false
                    })
            })
        }
        else {
            self.iconImageView.image = newImage
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.selectionStyle = UITableViewCellSelectionStyle.None
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        let animations = {
            if selected {
                self.backgroundColor = CELL_SELECTED_BG_COLOR
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
                self.backgroundColor = CELL_SELECTED_BG_COLOR
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

}














