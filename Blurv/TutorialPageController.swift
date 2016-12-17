//
//  TutorialPageController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-15.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

protocol TutorialPageDataSource {
    func tutorialPageController(controller:TutorialPageController, textForPageIndex index:Int) -> String?
    func tutorialPageController(controller:TutorialPageController, imageForPageIndex index:Int) -> UIImage?
}


class TutorialPageController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    
    private var text:String? {
        get {
            return self.dataSource?.tutorialPageController(self, textForPageIndex: Int(self.pageIndex))
        }
    }
    private var image:UIImage? {
        get {
            return self.dataSource?.tutorialPageController(self, imageForPageIndex: Int(self.pageIndex))
        }
    }
    
    var pageIndex:Int = 0
    var dataSource:TutorialPageDataSource?

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadContent()
    }
    
    
    func loadContent() {
        
        label.text = self.text
        imageView.image = self.image
        
    }
}
