//
//  AppDelegate.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-15.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import Parse
import FBSDKCoreKit
import ParseFacebookUtilsV4
import SVProgressHUD


let blurv_color = UIColor(hue: 0, saturation: 0.0, brightness: 1, alpha: 1)
let navbar_title_font = UIFont(name: "Montserrat-Bold", size: 17.0)!
let navbar_color = UIColor(hue: (213/360), saturation: 0.234, brightness: 0.184, alpha: 1)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var showingNewMatch:Bool = false
    
    class func bundleId() -> String! {
        return NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as! String
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        application.applicationSupportsShakeToEdit = true
        
        AppDelegate.applyAppearance()
        application.statusBarStyle = UIStatusBarStyle.LightContent
        
        BLNotification.registerSubclass()
        BLUser.registerSubclass()
        StaticQuestion.registerSubclass()
        BLAdjective.registerSubclass()
        BLPhrase.registerSubclass()
        BLReport.registerSubclass()
 
        
        // MARK: SDKs

        Parse.enableLocalDatastore()
        
        let parseConfig = ParseClientConfiguration { (config:ParseMutableClientConfiguration) in
            config.applicationId = "a15fa72f061e4c5fb76263fdbd8a6459"
            config.server = "https://blurv.herokuapp.com/parse-beta"
        }
        Parse.initializeWithConfiguration(parseConfig)
        
        NotificationManager.sharedManager.updateInstallation()
      
        
        Fabric.with([Crashlytics.self])
        
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)

        
        if let notif = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject:AnyObject] {
            self.application(application, didReceiveRemoteNotification: notif)
        }
        
        
        return true
    }
    
    
    class func applyAppearance() {
        
        let buttonColor = UIColor(hue: 0.96, saturation: 0.89, brightness: 0.84, alpha: 1)
        let barButtonItemFontAttributes = [NSFontAttributeName:UIFont(name: "Montserrat-Regular", size: 18.0)!, NSForegroundColorAttributeName:buttonColor]
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemFontAttributes, forState: UIControlState.Normal)
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -1000, vertical: 0), forBarMetrics: .Default)
        
    
        let navigationBarTitleFontAttributes = [NSFontAttributeName:navbar_title_font, NSForegroundColorAttributeName:blurv_color]
        UINavigationBar.appearance().tintColor = blurv_color
        UINavigationBar.appearance().barTintColor = navbar_color
        UINavigationBar.appearance().titleTextAttributes = navigationBarTitleFontAttributes
        //UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        
        //UINavigationBar.appearance().bar
        
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Clear)
        SVProgressHUD.setFont(UIFont(name: "Montserrat-Regular", size: 14.0))
        SVProgressHUD.setForegroundColor(UIColor(hue: (219/360), saturation: 0.11, brightness: 0.82, alpha: 1.0))
    }
    
    class func resetAppearance() {
        UIBarButtonItem.appearance().setTitleTextAttributes(nil, forState: UIControlState.Normal)
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffsetZero, forBarMetrics: UIBarMetrics.Default)
        UINavigationBar.appearance().titleTextAttributes = nil
        UINavigationBar.appearance().tintColor = nil
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { 
            NotificationManager.sharedManager.fetchAllUnread()
        }
        
        BlurvClient.sharedClient.checkReports { (blocked, user, error) in
            if blocked == true && user != nil {
                if let visible = self.visibleViewController() {
                    if let home = self.popToHomeFrom(viewController: visible) {
                        home.showLogin(true, lockedAccount: user!)
                    }
                }
            }
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if runningInForeground() {
            NotificationManager.sharedManager.handleForegroundNotification(userInfo)
        }
        else {
            NotificationManager.sharedManager.handleBackgroundNotification(userInfo)
        }
    }
    
    func popToHomeFrom(viewController vc:UIViewController) -> HomeController? {
        AppDelegate.applyAppearance()
        if vc is HomeController { return (vc as! HomeController) }
        if let presenting = vc.presentingViewController {
            if !(presenting is LoadingController) {
                vc.dismissViewControllerAnimated(true, completion: nil)
                if let nav = presenting as? UINavigationController {
                    nav.popToRootViewControllerAnimated(false)
                    return self.popToHomeFrom(viewController: nav.viewControllers.first!)
                }
                else {
                    return self.popToHomeFrom(viewController: vc.presentingViewController!)
                }
            }
        }
        if let navRoot = vc.navigationController?.viewControllers.first {
            vc.navigationController?.popToRootViewControllerAnimated(false)
            return self.popToHomeFrom(viewController: navRoot)
        }
        else {
            return nil
        }
    }
    
    class func routeToGame(game:Game, pushQuestion index:Int? = nil) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let visible = appDelegate.visibleViewController() {
            if visible is GameController {
                if (visible as? GameController)?.game.id == game.id {
                    (visible as! GameController).setUpdatedGame(game)
                    if index != nil {
                        (visible as? GameController)?.pushToQuestionWithIndex(index!)
                    }
                    return
                }
            }
            if let home = appDelegate.popToHomeFrom(viewController: visible) {
                home.goToMessages(self)
                home.setMessagesMode(.Blurvs, animated: false)
                let gameVC = home.storyboard!.instantiateViewControllerWithIdentifier("GameController") as! GameController
                gameVC.game = game
                if index != nil {
                    home.navigationController?.pushViewController(gameVC, animated: false)
                    gameVC.pushToQuestionWithIndex(index!)
                }
                else {
                    home.navigationController?.pushViewController(gameVC, animated: true)
                }
            }
        }
    }
    
    class func routeToChat(chat:Chat) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let visible = appDelegate.visibleViewController() {
            if visible is ChatController {
                if (visible as? ChatController)?.chat.id == chat.id {
                    return
                }
            }
            if let home = appDelegate.popToHomeFrom(viewController: visible) {
                home.goToMessages(self)
                home.setMessagesMode(.Chats, animated: false)
                let chatVC = home.storyboard!.instantiateViewControllerWithIdentifier("ChatController") as! ChatController
                chatVC.chat = chat
                home.navigationController?.pushViewController(chatVC, animated: true)
            }
        }
    }

    class func showMatch(game: Game) {
        if let visible = (UIApplication.sharedApplication().delegate as? AppDelegate)?.visibleViewController() {
            if visible is ItsAMatchController { return }
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ItsAMatchController") as! ItsAMatchController
            vc.game = game
            vc.modalPresentationStyle = .OverCurrentContext
            visible.presentViewController(vc, animated: true, completion: nil)
            GameManager.sharedManager.setPoppedUpForGame(game)
        }
    }
    class func showNewPicture(game: Game, pictureIndex:Int) {
        if let visible = (UIApplication.sharedApplication().delegate as? AppDelegate)?.visibleViewController() {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("NewPictureController") as! NewPictureController
            vc.modalPresentationStyle = .OverCurrentContext
            vc.game = game
            let pictureId = game.otherUser!.currentPictureIds[pictureIndex]
            PicturesManager.sharedInstance.getImageForPictureID(pictureId, minimumSize: UIScreen.mainScreen().bounds.height, callback: { (image, error) in
                if image != nil {
                    vc.image = image
                    visible.presentViewController(vc, animated: true, completion: nil)
                }
            })
        }
    }
    class func showChatUnlocked(game: Game) {
        if let visible = (UIApplication.sharedApplication().delegate as? AppDelegate)?.visibleViewController() {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ChatUnlockedController") as! ChatUnlockedController
            vc.game = game
            vc.modalPresentationStyle = .OverCurrentContext
            visible.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func runningInForeground() -> Bool {
        let state = UIApplication.sharedApplication().applicationState
        return state == UIApplicationState.Active
    }

    class func visibleViewController() -> UIViewController? {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).visibleViewController()
    }
    func visibleViewController(rootVC:UIViewController? = nil) -> UIViewController? {
        
        var root = rootVC
        
        if root == nil {
            root = UIApplication.sharedApplication().keyWindow?.rootViewController
        }
        
        if root?.presentedViewController == nil {
            return root
        }
        
        if let presented = root?.presentedViewController {
            if presented.isKindOfClass(UINavigationController) {
                let navigationController = presented as! UINavigationController
                return visibleViewController(navigationController.viewControllers.last!)
            }
            
            if presented.isKindOfClass(UITabBarController) {
                let tabBarController = presented as! UITabBarController
                return tabBarController.selectedViewController!
            }
            
            return visibleViewController(presented)
        }
        return nil
    }
    
    
}





