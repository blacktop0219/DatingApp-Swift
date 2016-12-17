//
//  NewMatchCell.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class NewMatchCell: UICollectionViewCell {
    
    @IBOutlet weak var pictureView: PictureView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var user:BLUser!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        pictureView.hideWhenNoPicture = true
        pictureView.layer.cornerRadius = pictureView.frame.width / 2
        pictureView.tapGesture.enabled = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        pictureView.layer.cornerRadius = pictureView.frame.width / 2
        
    }
    
    func populateWithUser(user:BLUser) {
        self.user = user
        
        nameLabel.text = user.firstName
        pictureView.pictureId = nil
        pictureView.pictureId = user.currentPictureIds.first
        pictureView.blur = true
        let lockedImage = UIImage(named: "image_lock")
        let lockedImageView = UIImageView(image: lockedImage)
        lockedImageView.frame = CGRect(x:0, y: 0, width: pictureView.frame.width, height: pictureView.frame.width)
        pictureView.addSubview(lockedImageView)
    }
    
}
