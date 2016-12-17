//
//  TutorialContentController.swift
//  Blurv
//
//  Created by dev on 8/24/16.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class TutorialContentController: UIViewController {
    
    @IBOutlet weak var bkImage: UIImageView!
    
    
    var pageIndex: Int!
    var imageName:String!
    var buttonText:String!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.bkImage.image = UIImage(named: imageName)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
