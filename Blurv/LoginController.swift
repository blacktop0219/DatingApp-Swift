//
//  LoginController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-15.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import ParseFacebookUtilsV4
import SVProgressHUD
import Firebase
import MessageUI

class LoginController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, TutorialPageDataSource, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var pageControl: UIPageControl!
        
    @IBOutlet weak var tutorialView: UIView!
    let pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    var pageControllers:[TutorialPageController] = []
    
    let texts:[String] = [TUTORIAL_TEXT_1, TUTORIAL_TEXT_2, TUTORIAL_TEXT_3]
    let imageNames:[String] = [TUTORIAL_IMAGE_1, TUTORIAL_IMAGE_2, TUTORIAL_IMAGE_3]
    
    var lockedUser:BLUser?
    
    private func showLockedAccount(user:BLUser) {
        let title = NSLocalizedString("AccountLocked_title", comment: "")
        let message = NSLocalizedString("AccountLocked_message", comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let contactAction = UIAlertAction(title: NSLocalizedString("Contact Us", comment: ""), style: UIAlertActionStyle.Default) { (action:UIAlertAction) in
            self.showcontactUs(user)
        }
        let dismissAction = UIAlertAction(title: NSLocalizedString("dismiss", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil)
        
        alert.addAction(contactAction)
        alert.addAction(dismissAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showcontactUs(user:BLUser) {
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
        
        let subject = NSLocalizedString("Account Recovery", comment: "")
        let body = String(format: NSLocalizedString("AccountRecoveryEmailBody", comment: ""), user.objectId!)
        
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
    
    
    // MARK: Actions
    @IBAction func login(sender: AnyObject) {
        let permissions = ["email", "public_profile", "user_friends", "user_photos", "user_birthday"]
       // activityIndicator.startAnimating()
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) { (user:PFUser?, error:NSError?) -> Void in
        //    self.activityIndicator.stopAnimating()
            if error == nil && user != nil {
                BlurvClient.sharedClient.setNeedsLocationUpdate(true)
                BlurvClient.sharedClient.firebaseLogin({ (success) in
                    if success {
                        NSNotificationCenter.defaultCenter().postNotificationName("NOTIFICATION_LOGIN", object: nil)
                        if user!.isNew {
                            SVProgressHUD.show()
                            BLUser.setupNewUser(user!, done: { (success) -> Void in
                                if success {
                                    SVProgressHUD.dismiss()
                                    self.didLogin()
                                }
                                else {
                                    let errorMessage = NSLocalizedString("Could not login.", comment: "")
                                    SVProgressHUD.showErrorWithStatus(errorMessage)
                                }
                            })
                        }
                        else {
                            BlurvClient.sharedClient.checkReports({ (blocked, user, error) in
                                if blocked != nil {
                                    if blocked! && user != nil {
                                        self.showLockedAccount(user!)
                                    }
                                    else {
                                        self.didLogin()
                                    }
                                }
                                else {
                                    let errorMessage = NSLocalizedString("Could not login.", comment: "")
                                    SVProgressHUD.showErrorWithStatus(errorMessage)
                                }
                            })
                        }
                    }
                    else {
                        let errorMessage = NSLocalizedString("Could not login.", comment: "")
                        SVProgressHUD.showErrorWithStatus(errorMessage)
                    }
                })
            }
            else {
                let errorMessage = NSLocalizedString("Could not login.", comment: "")
                SVProgressHUD.showErrorWithStatus(errorMessage)
            }
        }
    }
    
    func didLogin() {
        if let user = BLUser.currentUser() {
            FeedManager.sharedManager.loadFeedIfNeeded()
            BlurvClient.sharedClient.setNeedsLocationUpdate(true)
            BlurvClient.sharedClient.setActiveNow(true)
            PFInstallation.currentInstallation()["userId"] = user.objectId!
            PFInstallation.currentInstallation().saveInBackground()
            if user.profileComplete == false {
                self.performSegueWithIdentifier("CreateProfile", sender: self)
            }
            else {
                BlurvClient.sharedClient.setNeedsLocationUpdate(false)
                NSNotificationCenter.defaultCenter().postNotificationName("NOTIFICATION_BROWSE_LOAD_FEED", object: nil)
                NSNotificationCenter.defaultCenter().postNotificationName("NOTIFICATION_USER_LOGGED_IN", object: nil)
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        else {
            let errorMessage = NSLocalizedString("An error occured. Please try again later.", comment: "")
            SVProgressHUD.showErrorWithStatus(errorMessage)
        }
    }
    
    
    
    
    // MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "back_button")
        //self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "back_button")
        self.navigationController?.navigationBar.topItem?.title = ""
        
        createPages()
        setupPageViewController()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
       /* let backgroundImage = UIImage(named: "splash_ground")
        let backgroundView = UIImageView(image: backgroundImage!)
        backgroundView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height-200)
        self.view.addSubview(backgroundView)
        */
        if let user = BLUser.currentUser() {
            if lockedUser != nil {
                showLockedAccount(lockedUser!)
                lockedUser = nil
            }
            else if user.profileComplete == false {
                self.performSegueWithIdentifier("CreateProfile", sender: self)
            }
            else {
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // MARK: Notifs
        let userNotificationTypes: UIUserNotificationType = [.Alert, .Badge, .Sound]
        
        let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        BlurvClient.sharedClient.startLocationManager()
    }
    
    func createPages() {
        var idx = 0
        for _ in texts {
            let vc = storyboard?.instantiateViewControllerWithIdentifier("TutorialPageController") as! TutorialPageController
            vc.pageIndex = idx
            vc.dataSource = self
            pageControllers.append(vc)
            idx += 1
        }
    }
    func setupPageViewController() {
        pageViewController.delegate = self
        pageViewController.dataSource = self
        let firstPage = pageControllers[0]
        pageViewController.setViewControllers([firstPage], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        pageViewController.view.frame = self.tutorialView.frame
        addChildViewController(pageViewController)
        tutorialView.addSubview(pageViewController.view)
        tutorialView.sendSubviewToBack(pageViewController.view)
        pageViewController.didMoveToParentViewController(self)
    }
    
    // MARK: TutorialPageController DataSource
    func tutorialPageController(controller: TutorialPageController, imageForPageIndex index: Int) -> UIImage? {
        if imageNames.count > index {
            return UIImage(named: imageNames[index])
        }
        return nil
    }
    func tutorialPageController(controller: TutorialPageController, textForPageIndex index: Int) -> String? {
        return texts[index]
    }
    
    // MARK: UIPageViewController DataSource
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        let currentIndex = (viewController as! TutorialPageController).pageIndex
        if currentIndex + 1 >= texts.count {
            return nil
        }
        return pageControllers[currentIndex + 1]
    }
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let currentIndex = (viewController as! TutorialPageController).pageIndex
        if currentIndex == 0 { return nil }
        return pageControllers[currentIndex - 1]
    }
    func pageViewControllerPreferredInterfaceOrientationForPresentation(pageViewController: UIPageViewController) -> UIInterfaceOrientation {
        return UIInterfaceOrientation.Portrait
    }
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return texts.count
    }
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: UIPageViewController Delegate
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed {
            pageControl.currentPage = (pageViewController.viewControllers?.first as! TutorialPageController).pageIndex
        }
    }
    
    
}



