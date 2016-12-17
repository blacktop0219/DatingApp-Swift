//
//  PicturePageController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-03-09.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class PicturePageController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, PictureControllerDelegate {
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var containerCenterY: NSLayoutConstraint!
    var closeButton:UIButton!
    
    var pageController:UIPageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: [UIPageViewControllerOptionInterPageSpacingKey:10])
    
    var liveCache:[String:UIImage] = [:]
    
    var dismissing:Bool = false
    
    var pictureIds:[String]!
    private var picturesCount:Int {
        return self.pictureIds.count
    }
    private var maxIndex:Int {
        return self.pictureIds.count - 1
    }
    
    private var currentIndex:Int = 0
    private var nextIndex:Int?
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if dismissing {
            return .LightContent //.Default
        }
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(PicturePageController.handlePan(_:)))
        self.view.addGestureRecognizer(panGesture)
    }
    
    override func viewWillAppear(animated: Bool) {
        loadPageController()
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    private func viewControllerForPictureId(id:String, index:Int) -> UIViewController {
        let controller = storyboard!.instantiateViewControllerWithIdentifier("PictureController") as! PictureController
        controller.pictureId = id
        controller.index = index
        controller.delegate = self
        return controller
    }
    
    func loadPageController() {
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.frame = self.container.frame
        addChildViewController(pageController)
        container.addSubview(pageController.view)
        pageController.didMoveToParentViewController(self)
        
        closeButton = UIButton(frame: CGRect(x: 0, y: 20, width: 60, height: 60))
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        closeButton.setImage(UIImage(named: "close_button"), forState: .Normal)
        closeButton.tintColor = UIColor.whiteColor()
        closeButton.addTarget(self, action: #selector(PicturePageController.close), forControlEvents: .TouchUpInside)
        self.view.addSubview(closeButton)
    }
    
    
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if currentIndex == maxIndex { return nil }
        else {
            let picId = pictureIds[currentIndex + 1]
            let vc = viewControllerForPictureId(picId, index: currentIndex + 1)
            return vc
        }
    }
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if currentIndex == 0 { return nil }
        else {
            let picId = pictureIds[currentIndex - 1]
            let vc = viewControllerForPictureId(picId, index: currentIndex - 1)
            return vc
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let newVC = pageViewController.viewControllers?.first as? PictureController {
            self.currentIndex = newVC.index
        }
    }
    
    
    func setInitialIndex(index:Int) {
        self.currentIndex = index
        if index < pictureIds.count {
            let picId = pictureIds[index]
            let vc = viewControllerForPictureId(picId, index: index)
            pageController.setViewControllers([vc], direction: .Forward, animated: false, completion: nil)
        }
        else {
            if let picId = pictureIds.first {
                let vc = viewControllerForPictureId(picId, index: index)
                pageController.setViewControllers([vc], direction: .Forward, animated: false, completion: nil)
            }
        }
    }

    func close() {
        self.dismiss()
    }
    
    func dismiss(direction:Int = 0) {
        dismissing = true
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.2, options: .BeginFromCurrentState, animations: { () -> Void in
            if direction < 0 {
                self.containerCenterY.constant = -self.view.frame.height
            }
            else {
                self.containerCenterY.constant = self.view.frame.height
            }
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.layoutIfNeeded()
            self.view.backgroundColor = UIColor.clearColor()
            self.closeButton.alpha = 0
            }) { (complete:Bool) -> Void in
                self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    
    func handlePan(gesture:UIPanGestureRecognizer) {
        let translation = gesture.translationInView(self.view).y
        let velocity = gesture.velocityInView(self.view).y
        
        let thresholdVelocity:CGFloat = 800
        let ratio = container.frame.origin.y / self.view.frame.height
        print(ratio)
        
        switch gesture.state {
        case .Began, .Changed:
            containerCenterY.constant += translation
            self.view.layoutIfNeeded()
            let opacity = 1 - fabs(ratio)
            self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(opacity)
            self.closeButton.alpha = opacity
        default:
            if fabs(ratio) > 0.35 || fabs(velocity) > thresholdVelocity {
                dismiss(Int(velocity / fabs(velocity)))
            }
            else {
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.2, options: .BeginFromCurrentState, animations: { () -> Void in
                    self.containerCenterY.constant = 0
                    self.view.layoutIfNeeded()
                    self.view.backgroundColor = UIColor.blackColor()
                    self.closeButton.alpha = 1
                    }, completion: nil)
            }
        }
        gesture.setTranslation(CGPointZero, inView: self.view)
    }
    
    
    func pictureControllerDidLoadImage(image: UIImage, pictureId: String) {
        liveCache[pictureId] = image
    }
    
    func pictureForPictureId(pictureId: String) -> UIImage? {
        if let image = liveCache[pictureId] {
            return image
        }
        return nil
    }

}
