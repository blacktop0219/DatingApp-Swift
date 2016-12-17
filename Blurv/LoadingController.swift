//
//  LoadingController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse

class LoadingController: UIViewController {

    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var phraseLabel: UILabel!
    
    var blurredLogo: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

     /*   logo.alpha = 0
        phraseLabel.alpha = 0
        blurredLogo = UIImageView(image: UIImage(named: "splash_logo_blurred"))
        blurredLogo.contentMode = .Center
        
        self.view.addSubview(blurredLogo)*/
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.performStartupFetch()
    }
    
    override func viewDidLayoutSubviews() {
       // blurredLogo.frame = logo.frame
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidAppear(animated: Bool) {
       /* UIView.animateWithDuration(1.2, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.logo.alpha = 1.0
            self.blurredLogo.alpha = 0.0
            }) { (complete:Bool) -> Void in
        }*/
    }

    func performStartupFetch() {
        BlurvClient.sharedClient.loadAllRequiredItems {
            if BLUser.currentUser() != nil {
                BlurvClient.sharedClient.setNeedsLocationUpdate(true)
                BlurvClient.sharedClient.firebaseLogin({ (success) in
                    if success {
                        self.ready()
                    }
                })
            }
            else {
                BLUser.logOut()
                self.ready()
            }
        }
    }
    
    func ready() {
        UIView.animateWithDuration(0.8, animations: { () -> Void in
            self.phraseLabel.alpha = 1
            }) { (complete:Bool) -> Void in
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC)*0.8)), dispatch_get_main_queue()) { () -> Void in
                    self.performSegueWithIdentifier("EnterApp", sender: self)
                    BlurvClient.setAppLoaded()
                }
        }
    }
}
















