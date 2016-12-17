//
//  SettingsController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-21.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import MessageUI
import SVProgressHUD


let SETTINGS_DEFAULT_BG_HEIGHT:CGFloat = 210

protocol SettingsControllerDelegate {
    func settingsController(controller:SettingsController, viewDidAppear animated:Bool)
}

class SettingsController: UIViewController, UIScrollViewDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var topBGHeight: NSLayoutConstraint!
    
    @IBOutlet weak var blurredImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pictureView: PictureView!
    @IBOutlet weak var firstNameLabel: UILabel!
    
    @IBOutlet weak var profileView: UIView!
    
    var delegate:SettingsControllerDelegate?
    
    var loaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsController.loadProfile), name: "NOTIFICATION_PROFILE_CHANGED", object: nil)
        
        setupScrollView()
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.delegate?.settingsController(self, viewDidAppear: animated)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadProfile()
    }
   
    
    func setupScrollView() {
        scrollView.delegate = self
    }
    
    func loadProfile() {
        if let user = BLUser.currentUser() {
            firstNameLabel.text = user.firstName
            
            if let picId = user.currentPictureIds.first {
                pictureView.pictureId = picId
                
               /* PicturesManager.sharedInstance.getImageForPictureID(picId, minimumSize: 400, callback: { (image, error) -> Void in
                    if image != nil {
                        self.loaded = true
                        self.blurredImageView.alpha = 0
                        self.blurredImageView.image = image!.applyDarkEffect()
                        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.9, options: .CurveEaseOut, animations: { () -> Void in
                            self.blurredImageView.alpha = 1
                            }, completion: nil)
                    }
                })*/
            }
        }
    }


    func updateTopBackground(offset:CGFloat) {
        topBGHeight.constant = SETTINGS_DEFAULT_BG_HEIGHT - offset
        self.view.layoutIfNeeded()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        updateTopBackground(offsetY)
    }
    @IBAction func showProfile(sender: AnyObject) {
        let profileVC = storyboard?.instantiateViewControllerWithIdentifier("ProfileController") as! ProfileViewController
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    @IBAction func discoveryPreferences(sender: AnyObject) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("DiscoveryPreferencesController") as! DiscoveryPreferencesController
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func appSettings(sender: AnyObject) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("AppSettingsController") as! AppSettingsController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func submitQuestion(sender: AnyObject) {
        if !MFMailComposeViewController.canSendMail() {
            let alertTitle = NSLocalizedString("error", comment: "")
            let alertMessage = NSLocalizedString("email_not_supported", comment: "")
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "dismiss", style: .Cancel, handler: nil)
            alertController.addAction(dismissAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        let composeVC = MFMailComposeViewController()
        
        let subject = NSLocalizedString("Question Suggestion", comment: "Mailto: subject for Question Suggestion")
        let body = NSLocalizedString("I'd like to suggest the following question:\n", comment: "Mailto: body for Question Suggestion")
        
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients(["Hello@godowntochat.com"])
        composeVC.setSubject(subject)
        composeVC.setMessageBody(body, isHTML: false)
        
        AppDelegate.resetAppearance()

        self.presentViewController(composeVC, animated: true, completion: nil)
    }
    
    @IBAction func shareTheApp(sender: AnyObject) {
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
    @IBAction func contactUs(sender: AnyObject) {
        if !MFMailComposeViewController.canSendMail() {
            let alertTitle = NSLocalizedString("error", comment: "")
            let alertMessage = NSLocalizedString("email_not_supported", comment: "")
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "dismiss", style: .Cancel, handler: nil)
            alertController.addAction(dismissAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        let composeVC = MFMailComposeViewController()
        
        let subject = NSLocalizedString("Feedback about Down To Chat", comment: "Mailto: subject for Contact")
        let body = NSLocalizedString("Dear Down To Chat Team,\n", comment: "")
        
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients(["Hello@godowntochat.com"])
        composeVC.setSubject(subject)
        composeVC.setMessageBody(body, isHTML: false)
        
        AppDelegate.resetAppearance()
        self.presentViewController(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController,
        didFinishWithResult result: MFMailComposeResult, error: NSError?) {
            // Check the result or perform other tasks.
            
            // Dismiss the mail compose view controller.
            AppDelegate.applyAppearance()
            controller.dismissViewControllerAnimated(true, completion: nil)
    }
}









