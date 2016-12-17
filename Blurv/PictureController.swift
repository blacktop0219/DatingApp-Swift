//
//  PictureController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-03-09.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

protocol PictureControllerDelegate {
    func pictureControllerDidLoadImage(image:UIImage, pictureId:String)
    func pictureForPictureId(pictureId:String) -> UIImage?
}

class PictureController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var pictureId:String!
    var index:Int!
    
    var delegate:PictureControllerDelegate?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if imageView.image == nil && pictureId != nil {
            if let theImage = self.delegate?.pictureForPictureId(pictureId!) {
                setImage(theImage, animated: false)
            }
            else {
                activityIndicator.startAnimating()
                PicturesManager.sharedInstance.getImageForPictureID(pictureId!, minimumSize: self.view.bounds.width) { (image, error) -> Void in
                    if image != nil {
                        self.delegate?.pictureControllerDidLoadImage(image!, pictureId: self.pictureId)
                        self.setImage(image!, animated: true)
                    }
                }
            }
        }
    }
    
    
    func setImage(image:UIImage, animated:Bool) {
        if animated {
            self.imageView.alpha = 0
            self.activityIndicator.stopAnimating()
            self.imageView.image = image
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.imageView.alpha = 1.0
            })
        }
        else {
            self.imageView.image = image
        }
    }
    
}
