//
//  BLHudController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-03-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class BLHudController: UIViewController {

    @IBOutlet weak var container: CustomView!
    @IBOutlet weak var textLabel: UILabel!
    
    var dismissAfter:NSTimeInterval = 1
    
    var dismissTimer:NSTimer!
    
    var text:String = "" {
        didSet {
            self.textLabel?.text = text
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.dismissTimer = NSTimer.scheduledTimerWithTimeInterval(self.dismissAfter, target: self, selector: #selector(BLHudController.dismiss), userInfo: nil, repeats: false)
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(BLHudController.dismiss))
        self.view.addGestureRecognizer(tapGR)
        
        self.container.transform = CGAffineTransformMakeScale(1.5, 1.5)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.textLabel.text = self.text
        
        UIView.animateWithDuration(0.5, delay: 0.1, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.container.transform = CGAffineTransformIdentity
            }) { (completed:Bool) -> Void in
                // complete
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    

}
