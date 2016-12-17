//
//  AppSettingsController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-22.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import SVProgressHUD
import Parse

class AppSettingsController: UITableViewController {

    
    @IBOutlet weak var matchSwitch: UISwitch!
    @IBOutlet weak var answerSwitch: UISwitch!
    @IBOutlet weak var messageSwitch: UISwitch!
    @IBOutlet weak var questionSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        loadCurrentPreferences()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func loadCurrentPreferences() {
        let user = BLUser.currentUser()!
        
        matchSwitch.setOn(user.notifyNewMatch, animated: false)
        answerSwitch.setOn(user.notifyNewAnswer, animated: false)
        messageSwitch.setOn(user.notifyNewMessage, animated: false)
        questionSwitch.setOn(user.notifyNewQuestion, animated: false)
    }

    @IBAction func logout(sender: AnyObject) {
        SVProgressHUD.show()
        BLUser.logOutInBackgroundWithBlock { (error:NSError?) -> Void in
            SVProgressHUD.dismiss()
            if error == nil {
                let hc = self.navigationController?.viewControllers.first as! HomeController
                hc.goToBrowse(self)
                NSNotificationCenter.defaultCenter().postNotificationName("NOTIFICATION_LOGOUT", object: nil)
                self.navigationController?.popToRootViewControllerAnimated(true)
                hc.showLogin(true, lockedAccount: nil)
            }
            else {
                SVProgressHUD.showErrorWithStatus(NSLocalizedString("Could not log out", comment: ""))
            }
        }
    }
    
    
    @IBAction func terms(sender: AnyObject) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        vc.url = NSURL(string: "http://www.blurv.com/terms.html")
        vc.title = NSLocalizedString("Terms of Use", comment: "")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func privacy(sender: AnyObject) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        vc.url = NSURL(string: "http://www.blurv.com/privacy.html")
        vc.title = NSLocalizedString("Privacy Policy", comment: "")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func safety(sender: AnyObject) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        vc.url = NSURL(string: "http://www.blurv.com/safety.html")
        vc.title = NSLocalizedString("Safety", comment: "")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func save(sender: AnyObject) {
        
        let user = BLUser.currentUser()!
        user.notifyNewMatch = matchSwitch.on
        user.notifyNewAnswer = answerSwitch.on
        user.notifyNewMessage = messageSwitch.on
        user.notifyNewQuestion = questionSwitch.on
        
        if user.notifyNewQuestion == false {
            NotificationManager.sharedManager.cancelAllLocalNotifications()
        }
        
        SVProgressHUD.show()
        user.saveInBackgroundWithBlock { (saved:Bool, error:NSError?) -> Void in
            SVProgressHUD.dismiss()
            if saved {
                self.navigationController?.popViewControllerAnimated(true)
            }
            else {
                
                SVProgressHUD.showErrorWithStatus(NSLocalizedString("Could not save settings. Please try again later.", comment: ""))
            }
        }
        
    }

}
