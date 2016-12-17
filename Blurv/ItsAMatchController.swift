//
//  ItsAMatchController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-26.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit


class ItsAMatchController: UIViewController {

    
    
    @IBOutlet weak var buttonStart: CustomButton!
    var game:Game!
    @IBOutlet weak var buttonKeepLooking: CustomButton!
    
    @IBOutlet weak var userLabel: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        setup()
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setNeedsStatusBarAppearanceUpdate()
        
       
      //  descriptionLabel.text = String(format: NSLocalizedString("You and %@ are interested in each other's profile", comment:""), game.otherUser!.firstName)
        userLabel.text = game.otherUser?.firstName
        
    }
    
    func setup() {
        let buttonIconInset = round(view.bounds.width * 0.12)
        buttonStart.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: buttonIconInset)
        buttonKeepLooking.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: buttonIconInset)
    }

    
    @IBAction func startBlurving(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            AppDelegate.routeToGame(self.game)
            //AppDelegate.setShowingNewMatch(false)
            NotificationManager.sharedManager.readNotificationsForGameWithId(self.game.id!)
        }
    }
    @IBAction func keepLooking(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            //AppDelegate.setShowingNewMatch(false)
            NotificationManager.sharedManager.readNotificationsForGameWithId(self.game.id!)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}
