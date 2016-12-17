//
//  BrowseController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-20.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Koloda
import SVProgressHUD
import AudioToolbox


class BrowseController: UIViewController, KolodaViewDataSource, KolodaViewDelegate, BlurvDropViewDelegate, FeedManagerDelegate {
    
    private let skipButtonColor = UIColor(red:0.169, green:0.702, blue:0.788, alpha:1)
    private let undoButtonColor = UIColor(red:1, green:0.588, blue:0, alpha:1)
    private let disabledButtonColor = UIColor.blackColor().colorWithAlphaComponent(0.15)
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var actionButtonsConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var browseView: KolodaView!
    @IBOutlet weak var dropView: BlurvDropView!
    @IBOutlet weak var undoButton: CustomButton!
    @IBOutlet weak var skipButton: CustomButton!

    @IBOutlet var outOfUsersItems: [UIView]!
    
    let actionButtonsBottom:(hidden:CGFloat, shown:CGFloat) = (-80, 16)
    
    @IBOutlet weak var noOneImage: UIImageView!
    
    @IBOutlet weak var inviteButton: UIButton!
    
    var lastDislikedUser:BLUser?
    
    var feed:[FeedUser] {
        return FeedManager.sharedManager.feed
    }
    
    private var busy:Bool = false
    
    // MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: Setup
    func setup() {
        setupBrowseView()
        setupButtons()
        dropView.delegate = self
        FeedManager.sharedManager.delegate = self
    }
    func setupBrowseView() {
        browseView.backgroundColor = UIColor.clearColor()
        browseView.dataSource = self
        browseView.delegate = self
        
        for v in self.outOfUsersItems {
            v.alpha = 0
        }
        self.noOneImage.alpha = 0
        self.inviteButton.alpha = 0
    }
    func setupButtons() {
       // skipButton.tintColor = disabledButtonColor
       // undoButton.tintColor = disabledButtonColor
        skipButton.enabled = false
        undoButton.enabled = false
    }

    // MARK: Feed Manager Delegate
    func feedManagerDidStartLoadingFeed(manager: FeedManager) {
        dropView.startAnimating()
    }
    func feedManagerDidLoadFeed(manager: FeedManager, isEmpty: Bool) {
        browseView.reloadData()
        dropView.stopAnimating()
        setActionButtonsHidden(isEmpty, animated: true)
    }
    func feedManagerDidClearFeed(manager: FeedManager) {
        browseView.reloadData()
        dropView.stopAnimating()
        setActionButtonsHidden(true, animated: true)
    }
    
    func feedManager(manager: FeedManager, undoStateChanged canUndo: Bool) {
       /* UIView.animateWithDuration(0.3) {
            self.undoButton.tintColor = canUndo ? self.undoButtonColor:self.disabledButtonColor
        }*/
        undoButton.enabled = canUndo
    }
    func feedManager(manager: FeedManager, skipStateChanged canSkip: Bool) {
        /*UIView.animateWithDuration(0.3) {
            self.skipButton.tintColor = canSkip ? self.skipButtonColor:self.disabledButtonColor
        }*/
        skipButton.enabled = canSkip
    }
    
    
    // MARK: DropView
    func dropViewDidChangeDirection(direction: Int) {
        let angle:CGFloat = CGFloat(M_PI)
        
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.7, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.dropView.transform = direction == 1 ? CGAffineTransformIdentity:CGAffineTransformMakeRotation(angle)
            }, completion: nil)
    }
    func dropViewDidGetTapped(dropView: BlurvDropView) {
        if dropView.animating == false {
            FeedManager.sharedManager.loadFeedIfNeeded()
        }
    }
    func dropViewDidStartAnimating(dropView: BlurvDropView) {
        self.setFeedEmpty(false, animated: true)
    }
    func dropViewDidStopAnimating(dropView: BlurvDropView) {
        self.setFeedEmpty(FeedManager.sharedManager.isFeedEmpty(), animated: true)
    }
    



    // MARK: Actions
    
    @IBAction func changeDiscoveryPreferences(sender: AnyObject) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("DiscoveryPreferencesController") as! DiscoveryPreferencesController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func rewind(sender: AnyObject) {
        FeedManager.sharedManager.undo { (success) in
            if success {
                self.browseView.revertAction()
            }
        }
    }
    
    @IBAction func like(sender: AnyObject) {
        
        browseView.swipe(SwipeResultDirection.Right)
    }
    
    @IBAction func dislike(sender: AnyObject) {
        browseView.swipe(SwipeResultDirection.Left)
    }
    
    @IBAction func next(sender: AnyObject) {
        FeedManager.sharedManager.sendUserToBack(browseView.currentCardIndex)
        browseView.resetCurrentCardIndex()
    }
    
    @IBAction func inviteFriends(sender: AnyObject) {
        
        var itemsToShare = [AnyObject]()
        let text = NSLocalizedString("Check out Down To Chat on the Appstore! ", comment: "Share the app message body")
        itemsToShare.append(text)
        BlurvClient.getAppStoreTrackId { (id) -> Void in
            if let shareURL = BlurvClient.appStoreLinkWithAppId(id) {
                itemsToShare.append(shareURL)
            }
            let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
            self.presentViewController(activityVC, animated: true, completion: nil)
        }

    }
    
   
    // MARK: Koloda View
    
    func kolodaNumberOfCards(koloda: KolodaView) -> UInt {
        return UInt(feed.count)
    }

    func koloda(koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView {
        
        let cardView = UIView(frame: browseView.bounds)
        cardView.layer.cornerRadius = 5.0
        cardView.backgroundColor = UIColor.clearColor()

        let contentView = NSBundle.mainBundle().loadNibNamed("BrowseCard", owner: self, options: nil).first! as! BrowseCard
        contentView.frame = browseView.bounds
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.feedUser = feed[Int(index)]

        cardView.addSubview(contentView)

        let metrics = ["width":cardView.bounds.width, "height": cardView.bounds.height]
        let views = ["contentView": contentView, "cardView": cardView]
        cardView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView(width)]", options: .AlignAllLeft, metrics: metrics, views: views))
        cardView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView(height)]", options: .AlignAllLeft, metrics: metrics, views: views))
        
        return cardView
    }
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView? {
        let view = CustomKolodaOverlay(frame: self.browseView.bounds)
        return view
    }

    func kolodaDidRunOutOfCards(koloda: KolodaView) {
        FeedManager.sharedManager.shouldClear = true
    }
    
    func koloda(koloda: KolodaView, didSwipeCardAtIndex index: UInt, inDirection direction: SwipeResultDirection) {
        let tutorialChecked = self.defaults.stringForKey("tutorialchecked")
        if tutorialChecked == nil || tutorialChecked!.isEmpty {
           self.performSegueWithIdentifier("EnterTutorial", sender: nil)
            

        } else {
        switch direction {
        case .Right:
            FeedManager.sharedManager.likeAtIndex(Int(index))
        case .Left:
            FeedManager.sharedManager.dislikeAtIndex(Int(index))
        default:
            break
        }
        }
    }
    
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt) {
        let profileVC = storyboard?.instantiateViewControllerWithIdentifier("ProfileController") as! ProfileViewController
        profileVC.user = feed[Int(index)].user
        profileVC.fromBrowse = true
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    func kolodaShouldTransparentizeNextCard(koloda: KolodaView) -> Bool {
        return false
    }
    
    
    // MARK: Utility
    func setActionButtonsHidden(hidden:Bool, animated:Bool, completion:(() -> Void)? = nil) {
        let animations = {
            var constant:CGFloat!
            if hidden { constant = self.actionButtonsBottom.hidden }
            else { constant = self.actionButtonsBottom.shown }
            self.actionButtonsConstraint.constant = constant
            self.view.layoutIfNeeded()
        }
        
        if animated {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                animations()
                }, completion: nil)
        }
        else {
            animations()
        }
    }
    func setFeedEmpty(empty:Bool, animated:Bool) {
        let anims = {
            for aView in self.outOfUsersItems {
                aView.alpha = empty ? 1:0
            }
            self.noOneImage.alpha = empty ? 1:0
            self.inviteButton.alpha = empty ? 1:0
            self.browseView.alpha = empty ? 0:1
        }
        if animated {
            UIView.animateWithDuration(0.3, animations: { 
                anims()
            })
        }
        else {
            anims()
        }
    }
    
}













