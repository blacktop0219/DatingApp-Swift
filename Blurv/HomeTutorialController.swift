//
//  HomeTutorialController.swift
//  Blurv
//
//  Created by dev on 8/24/16.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class HomeTutorialController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pageviewController: UIPageViewController?
    var pageTitles: NSArray?
    var pageImages: NSArray?
    var currentIndex: Int!
    
    @IBOutlet weak var gotItButton: UIButton!
    @IBOutlet weak var pageView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        currentIndex = 0
        self.pageTitles = NSArray(objects: "LET'S DO THIS!","GOT IT!","GOT IT!", "YEP, GOT IT!", "STILL GET IT!", "SUPER!", "LET'S START!")
        self.pageImages = NSArray(objects: "image_tutorial1", "image_tutorial2", "image_tutorial3", "image_tutorial4", "image_tutorial5", "image_tutorial6", "image_tutorial7")
        self.gotItButton.setTitle((self.pageTitles![currentIndex] as! String), forState: .Normal)
        
        self.pageviewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? UIPageViewController
        
        self.pageviewController?.dataSource = self
        self.pageviewController?.delegate = self
        let startVC = self.viewControllerAtIndex(0) as TutorialContentController
        
        let viewControllers = NSArray(object: startVC)
        self.pageviewController?.setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: false, completion: nil)
        
        self.pageviewController?.view.frame = CGRect(x: 0, y: 0, width: self.pageView.frame.width, height: self.pageView.frame.height)
        self.addChildViewController(self.pageviewController!)
        self.pageView.addSubview((self.pageviewController?.view)!)
        self.pageviewController?.didMoveToParentViewController(self)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func viewControllerAtIndex(index:Int)->TutorialContentController{
        if ((self.pageTitles?.count == 0) || (index >= self.pageTitles?.count)) {
            return TutorialContentController()
        }
        let vc: TutorialContentController = self.storyboard?.instantiateViewControllerWithIdentifier("TutorialContentController") as! TutorialContentController
        vc.imageName = self.pageImages![index] as! String
        vc.buttonText = self.pageTitles![index] as! String
        vc.pageIndex = index
        vc.view.tag = index
      //  currentIndex = index
       // self.gotItButton.setTitle((self.pageTitles![currentIndex] as! String), forState: .Normal)
        return vc
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! TutorialContentController
        var index = vc.pageIndex as Int
       // currentIndex = index
        if (index == 0 || index == NSNotFound){
         //   self.gotItButton.setTitle(self.pageTitles![currentIndex] as? String, forState: .Normal)
           return nil
        }
        
        index -= 1
        
        return self.viewControllerAtIndex(index)
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! TutorialContentController
        var index = vc.pageIndex as Int
        
        if (index == NSNotFound){
            return nil
        }
       // currentIndex = index
        index += 1
        if (index == self.pageTitles?.count){
         //   self.gotItButton.setTitle(self.pageTitles![currentIndex] as? String, forState: .Normal)
            return nil
        }
        
        return self.viewControllerAtIndex(index)
    }
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (!completed)
        {
            return
        }
            currentIndex = pageviewController?.viewControllers!.first?.view.tag
            self.gotItButton.setTitle(self.pageTitles![currentIndex] as? String, forState: .Normal)
       
    }

    @IBAction func goNextPage(sender: AnyObject) {
        if currentIndex > 5 {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject("checked", forKey: "tutorialchecked")
            self.performSegueWithIdentifier("EnterApp2", sender: nil)
            
        } else {
            
            currentIndex = currentIndex + 1
           
            let startVC = self.viewControllerAtIndex(currentIndex) as TutorialContentController
            
            let viewControllers = NSArray(object: startVC)
            self.pageviewController?.setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: false, completion: nil)
            
            self.pageviewController?.view.frame = CGRect(x: 0, y: 0, width: self.pageView.frame.width, height: self.pageView.frame.height)
            
            self.addChildViewController(self.pageviewController!)
            self.pageView.addSubview((self.pageviewController?.view)!)
            self.pageviewController?.didMoveToParentViewController(self)
            
            self.gotItButton.setTitle(self.pageTitles![currentIndex] as? String, forState: .Normal)
        }
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
