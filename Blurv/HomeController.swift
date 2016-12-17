//
//  HomeController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse

protocol HomeControllerDelegate {
    func homeControllerDidChangeMessageMode(newMode:MessageMode)
    func onShowSearchBar()
    func onHideSearchBar()
}

class HomeController: BlurvViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var navbar: UIView!
    
    @IBOutlet weak var titleCenterY: NSLayoutConstraint!
    @IBOutlet weak var leftIconCenterX: NSLayoutConstraint!
    @IBOutlet weak var rightIconCenterX: NSLayoutConstraint!
    
    @IBOutlet weak var searchIconCenterX: NSLayoutConstraint!
    @IBOutlet weak var scrollView: CustomScrollView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var titleIcon: UIImageView!
    @IBOutlet weak var logoButton: UIButton!
    @IBOutlet weak var blurvSwitch: BLSwitch!
    
    @IBOutlet weak var searchButton: UIButton!
    
    var currentIndex:Int {
        get {
            if scrollView != nil {
                let x = scrollView.contentOffset.x
                let w = self.view.bounds.width
                return Int((x - (x % w)) / w)
            }
            else {
                return 1
            }
        }
    }
    var navBarAnimating:Bool = false
    
    var delegate:HomeControllerDelegate?
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        switch currentIndex {
        case 0:
            return .LightContent
        default:
            return .LightContent
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupObservers()
        setupNavigationBar()
        setupScrollView()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        logoButton.layer.allowsEdgeAntialiasing = true
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.updateNotificationViews()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        checkUser()
    }
    
    
    func setupObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeController.checkLocationServices), name: NOTIFICATION_LOCATION_SERVICES_STATUS, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeController.updateNotificationViews), name: "NOTIFICATION_GLOBAL_NOTIFICATION_COUNT_CHANGED", object: nil)
    }
    func checkUser() {
        if let user = BLUser.currentUser() {
            if (user["profileComplete"] as! Bool) == false {
                self.showLogin(true, lockedAccount: nil)
            }
            else {
                BlurvClient.sharedClient.setNeedsLocationUpdate(true)
                BlurvClient.sharedClient.checkReports({ (blocked, user, error) in
                    if blocked != nil {
                        if blocked == true && user != nil {
                            self.showLogin(true, lockedAccount: user)
                        }
                    }
                })
            }
        }
        else {
            self.showLogin(false, lockedAccount: nil)
        }
    }
    func setupScrollView() {
        scrollView.delegate = self
        self.scrollView.setContentOffset(CGPoint(x: self.view.frame.width, y: 0), animated: false)
    }
    func setupNavigationBar() {
        self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "back_button")
       // self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "back_button")
        self.navigationController?.navigationBar.topItem?.title = ""
       // self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        //self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        let buttonColor = UIColor(hue: 0.96, saturation: 0.89, brightness: 0.84, alpha: 1)
        self.navigationController?.navigationBar.tintColor = buttonColor

       // self.navigationController?.navigationBar.barTintColor = UIColor.blackColor()
        updateNavbar(1/2)
    }
    
    func updateNotificationViews() {
        rightButton.tintColor = NotificationManager.notificationCount > 0 ? blurv_color:UIColor(red: 0.773, green: 0.792, blue: 0.824, alpha: 1.0)
        
        blurvSwitch.setHasChatNotification(NotificationManager.sharedManager.hasChatNotifications())
        blurvSwitch.setHasGameNotification(NotificationManager.sharedManager.hasGameNotifications())
    }
    
    func showLogin(animated:Bool, lockedAccount:BLUser?) {
        let loginNavController = storyboard!.instantiateViewControllerWithIdentifier("LoginNavController") as! UINavigationController
        if lockedAccount != nil {
            if let loginVC = loginNavController.viewControllers.first as? LoginController {
                loginVC.lockedUser = lockedAccount
            }
        }
        self.presentViewController(loginNavController, animated: true) {
            
        }
    }
    
    func checkLocationServices() -> Bool {
        if BLUser.currentUser() == nil { return true }
        if !(CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == .AuthorizedAlways) {
            let vc = storyboard?.instantiateViewControllerWithIdentifier("LocationServicesDisabledController") as! LocationServicesDisabledController
            self.presentViewController(vc, animated: true, completion: nil)
            return false
        }
        return true
    }

    func setMessagesMode(mode:MessageMode, animated:Bool) {
        self.blurvSwitch.setSelectedMode(mode, animated: animated)
    }
    
    @IBAction func messageModeSwitchValueChanged(sender: BLSwitch) {
        self.delegate?.homeControllerDidChangeMessageMode(sender.selectedMode)
    }

    @IBAction func searchSession(sender: AnyObject) {
        self.delegate?.onShowSearchBar()
    }
    @IBAction func goToBrowse(sender: AnyObject) {
        self.scrollView.setContentOffset(CGPoint(x: self.view.frame.width, y: 0), animated: true)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC)*0.3)), dispatch_get_main_queue()) { () -> Void in
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            })
        }
        
    }
    
    @IBAction func goToMessages(sender: AnyObject) {
        self.scrollView.setContentOffset(CGPoint(x: 2*self.view.frame.width, y: 0), animated: true)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC)*0.3)), dispatch_get_main_queue()) { () -> Void in
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
                })
        }

    }
    
    @IBAction func goToSettings(sender: AnyObject) {
        self.scrollView.setContentOffset(CGPointZero, animated: true)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC)*0.3)), dispatch_get_main_queue()) { () -> Void in
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            })
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        if !navBarAnimating {
            let percent = offset / (2*self.view.bounds.width)
            
            updateNavbar(percent)
            self.delegate?.onHideSearchBar()
        }
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        UIView.animateWithDuration(0.2) { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    func updateNavbar(offsetPercent:CGFloat) {
        if offsetPercent > 1 || offsetPercent < 0 { return }
        
        let percent = offsetPercent
        let p2 = pow(percent, 2)
        
        let margin:CGFloat = 0.18*self.view.frame.width
        
        leftIconCenterX.constant = percent*(-self.view.frame.width + margin)
        rightIconCenterX.constant = (1-percent)*(self.view.frame.width - margin)
        titleCenterY.constant = (percent - 0.5)*(-self.view.frame.width + margin)
        searchIconCenterX.constant = 0.5*(self.view.frame.width - margin)
        
        rightButton.alpha = 4.8*p2 - 9.2*percent + 4.4//4.8 x2 - 9.2 x + 4.4
        leftButton.alpha = 20.79365*p2 - 7.1349*percent//20.79365079 x2 - 7.134920635 x
        titleIcon.alpha = -4*p2 + 4*percent
        blurvSwitch.alpha = -3 + 4*percent//4.8*p2 - 5.2*percent + 1.4//4.8x^2 - 5.2x + 1.4
        logoButton.alpha = 4.8*p2 - 5.2*percent + 1.4
        searchButton.alpha = -3 + 4*percent
        
        
        let s = 2.4*p2 - 2.4*percent + 1
        let tx = 98*p2 - 98*percent
        let ty = -8*p2 + 8*percent
        let scaleTransform = CGAffineTransformMakeScale(s, s)
        let translateTransform = CGAffineTransformMakeTranslation(tx, ty)
        let t = CGAffineTransformConcat(scaleTransform, translateTransform)
        logoButton.transform = t
        
        if percent >= 0.5 {
            let x = (percent - 0.5) * 2 // normalize
            let color = UIColor(hue: 0.6, saturation: 0.06*x, brightness: (-0.18)*x+1, alpha: 1.0)
            logoButton.tintColor = color
        }
        
        
        self.view.layoutIfNeeded()
    }
//
//    func itsAMatchStartBlurving(controller: ItsAMatchController, game: BLGame) {
//        let gameVC = storyboard?.instantiateViewControllerWithIdentifier("GameController") as! GameController
//        gameVC.game = game
//        self.goToMessages(self)
//        self.navigationController?.pushViewController(gameVC, animated: true)
//    }
//    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let messagesVC = segue.destinationViewController as? MessagesController {
            self.delegate = messagesVC
        }
    }
    
}






















