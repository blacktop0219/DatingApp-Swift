//
//  PictureView.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit


let PICTURE_VIEW_BADGE_RADIUS_LARGE:CGFloat = 16
let PICTURE_VIEW_BADGE_RADIUS_SMALL:CGFloat = 12
let PICTURE_VIEW_BADGE_INSET:CGFloat = 5
let PICTURE_VIEW_BADGE_OPACITY:CGFloat = 0.5


protocol PictureViewDelegate {
    func pictureViewDidTapPicture(view:PictureView)
}

@IBDesignable
class PictureView: UIView {

    var imageView:UIImageView!
    private var starBadgeView:UIView!
    private var regularBadgeView:UILabel!
    private var activityIndicator:UIActivityIndicatorView!
    
    var tapGesture:UITapGestureRecognizer!
    
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.CGColor
        }
    }
    
    var blur:Bool = false {
        didSet {
            if image != nil {
                if blur {
                    self.imageView.image = self.image.blurredForDisplaySize(self.bounds.size)
                }
                else {
                    imageView.image = self.image
                }
            }
        }
    }
    var hideWhenNoPicture:Bool = false {
        didSet {
            if hideWhenNoPicture == false && pictureId == nil {
                imageView.hidden = true
            }
        }
    }
    var badgeIndex:Int? {
        didSet {
            if badgeIndex != nil {
                if badgeIndex == 0 { starBadgeView.hidden = false; regularBadgeView.hidden = true }
                else {
                    starBadgeView.hidden = true
                    regularBadgeView.text = String(badgeIndex! + 1)
                    regularBadgeView.hidden = false
                }
            }
            else {
                starBadgeView.hidden = true
                regularBadgeView.hidden = true
            }
        }
    }
    
    var pictureId:String? = nil {
        didSet {
            if pictureId != nil {
                userId = nil
                imageView.hidden = false
                loading = true
                PicturesManager.sharedInstance.getImageForPictureID(pictureId!, minimumSize: self.frame.width, callback: { (image, error) -> Void in
                    self.loading = false
                    if image != nil {
                        self.image = image
                    }
                })
            }
            else {
                imageView.image = nil
                if hideWhenNoPicture && userId == nil {
                    imageView.hidden = true
                }
            }
        }
    }
    var userId:String? = nil {
        didSet {
            if userId != nil {
                pictureId = nil
                imageView.hidden = true
                self.loading = true
                PicturesManager.sharedInstance.getProfilePictureForFacebookId(userId!, callback: { (picture) -> Void in
                    self.loading = false
                    if picture != nil {
                        self.image = picture!
                    }
                })
            }
            else if hideWhenNoPicture && pictureId == nil {
                imageView.hidden = true
            }
        }
    }
    
    private var blurRadius:CGFloat {
        let height = self.image.size.height
        let width = self.image.size.width
        let factor = round(sqrt((height + width) / 2))
        let radius = round(factor * 1.6)
        return radius
    }
    private var loading:Bool = false {
        didSet {
            if loading {
                activityIndicator.startAnimating()
                imageView.hidden = true
            }
            else {
                activityIndicator.stopAnimating()
                imageView.hidden = false
            }
        }
    }

    private var image:UIImage! {
        didSet {
            if image != nil {
                imageView.contentMode = .ScaleAspectFill
                if blur {
                    self.imageView.image = self.image.blurredForDisplaySize(self.bounds.size)
                }
                else {
                    imageView.image = image
                }
            }
            else {
                imageView.image = nil
            }
        }
    }
    var delegate:PictureViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.clipsToBounds = true
        createImageViewAndActivityIndicator()
        createGestureRecognizer()
        createRegularBadge()
        createStarBadge()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.clipsToBounds = true
        createImageViewAndActivityIndicator()
        createGestureRecognizer()
        createRegularBadge()
        createStarBadge()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        adjustFrames()
    }
    
    func clear() {
        if pictureId != nil {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.imageView.alpha = 0
                }) { (complete:Bool) -> Void in
                    self.pictureId = nil
                    self.badgeIndex = nil
                    self.imageView.contentMode = .Center
                    self.imageView.image = UIImage(named: "no_picture")
                    
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        self.imageView.alpha = 1
                    })
            }
        }
    }
    
    private func createGestureRecognizer() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(PictureView.handleTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    private func createImageViewAndActivityIndicator() {
        self.imageView = UIImageView(frame: CGRectMake(0, 0, self.frame.width, self.frame.height))
        self.imageView.image = UIImage(named: "no_picture")
        imageView.contentMode = UIViewContentMode.Center
        self.addSubview(imageView)
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.hidesWhenStopped = true
        var newFrame = activityIndicator.frame
        newFrame.origin.x = (self.frame.width / 2) - (newFrame.width / 2)
        newFrame.origin.y = (self.frame.height / 2) - (newFrame.height / 2)
        activityIndicator.frame = newFrame
        self.addSubview(activityIndicator)
    }
    
    private func createStarBadge() {
        let radius = PICTURE_VIEW_BADGE_RADIUS_LARGE
        let circleFrame = CGRectMake(self.frame.width - ((radius * 2) + PICTURE_VIEW_BADGE_INSET), self.frame.height - ((radius * 2) + PICTURE_VIEW_BADGE_INSET), radius * 2, radius * 2)
        starBadgeView = UIView(frame: circleFrame)
        starBadgeView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(PICTURE_VIEW_BADGE_OPACITY)
        starBadgeView.layer.cornerRadius = radius
        
        // add "star" image
        let starImage = UIImageView(image: UIImage(named: "picture_star"))
        starImage.contentMode = UIViewContentMode.ScaleAspectFit
        var newFrame = starImage.frame
        newFrame.origin.x = (self.starBadgeView.frame.width / 2) - (newFrame.width / 2)
        newFrame.origin.y = (self.starBadgeView.frame.height / 2) - (newFrame.height / 2)
        starImage.frame = newFrame
        starBadgeView.addSubview(starImage)
        
        starBadgeView.hidden = true
        self.addSubview(starBadgeView)
    }
    
    private func createRegularBadge() {
        let radius = PICTURE_VIEW_BADGE_RADIUS_SMALL
        let labelFrame = CGRectMake(self.frame.width - ((radius * 2) + PICTURE_VIEW_BADGE_INSET), self.frame.height - ((radius * 2) + PICTURE_VIEW_BADGE_INSET), radius * 2, radius * 2)
        regularBadgeView = UILabel(frame: labelFrame)
        regularBadgeView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(PICTURE_VIEW_BADGE_OPACITY)
        regularBadgeView.font = UIFont(name: "Montserrat-Regular", size: 13.0)!
        regularBadgeView.textAlignment = .Center
        regularBadgeView.textColor = UIColor.whiteColor()
        regularBadgeView.clipsToBounds = true
        regularBadgeView.layer.cornerRadius = radius
        
        regularBadgeView.hidden = true
        self.addSubview(regularBadgeView)
    }
    
    private func adjustFrames() {
        // IMAGE VIEW
        let imageViewFrame = CGRectMake(0, 0, self.frame.width, self.frame.height)
        imageView?.frame = imageViewFrame
        
        // STAR BADGE
        var radius = PICTURE_VIEW_BADGE_RADIUS_LARGE
        let starBadgeFrame = CGRectMake(self.frame.width - ((radius * 2) + PICTURE_VIEW_BADGE_INSET), self.frame.height - ((radius * 2) + PICTURE_VIEW_BADGE_INSET), radius * 2, radius * 2)
        starBadgeView?.frame = starBadgeFrame
        
        // REGULAR BADGE
        radius = PICTURE_VIEW_BADGE_RADIUS_SMALL
        let labelFrame = CGRectMake(self.frame.width - ((radius * 2) + PICTURE_VIEW_BADGE_INSET), self.frame.height - ((radius * 2) + PICTURE_VIEW_BADGE_INSET), radius * 2, radius * 2)
        regularBadgeView?.frame = labelFrame
        
        // ACTIVITY INDICATOR
        if var newFrame = activityIndicator?.frame {
            newFrame.origin.x = (self.frame.width / 2) - (newFrame.width / 2)
            newFrame.origin.y = (self.frame.height / 2) - (newFrame.height / 2)
            activityIndicator?.frame = newFrame
        }
        
    }

    
    func handleTap(sender:UITapGestureRecognizer) {
        self.delegate?.pictureViewDidTapPicture(self)
    }
    
}
