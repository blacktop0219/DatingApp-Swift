//
//  MyProfileController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import SVProgressHUD
import FacebookImagePicker


enum MyProfileMode {
    case Create, Update
}


class MyProfileController: UITableViewController, UITextViewDelegate, PictureViewDelegate, OLFacebookImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var alertView: UIView!
    let fieldCharacterLimit:Int = 200
    
    
    @IBOutlet var textViews: [CustomTextView]!
    
    @IBOutlet weak var genderLabel: UILabel!
    
    @IBOutlet var pictureViews: [PictureView]!
    
    private var pictureIndexToChange:Int?
    
    private var picturesIds:[String] = [] {
        didSet {
            if picturesIds.count == 0 {
                for pView in self.pictureViews {
                    pView.clear()
                }
            }
            
            let idx_max = self.picturesIds.count - 1
            var idx = 0
            for pView in self.pictureViews {
                if idx > idx_max { pView.clear() }
                else {
                    if idx < 3 { pView.badgeIndex = idx }
                    pView.pictureId = picturesIds[idx]
                    idx += 1
                }
            }
        }
    }
    
    
    var genderIsMale:Bool? {
        didSet {
            if genderIsMale != nil {
                if navigationItem.rightBarButtonItem?.enabled == false {
                    navigationItem.rightBarButtonItem?.enabled = true
                }
                self.genderLabel.alpha = 0
                
                let male = NSLocalizedString("Male", comment: "")
                let female = NSLocalizedString("Female", comment: "")
                
                self.genderLabel.text = genderIsMale! ? male:female
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.genderLabel.alpha = 1
                })
            }
        }
    }
    
    var mode:MyProfileMode = .Create
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mode = BLUser.currentUser()!.profileComplete ? .Update:.Create
        
        self.setNeedsStatusBarAppearanceUpdate()
        setNavigationBarLayout()
        
        setupTextViews()
        setupTableView()
        additionnalSetup()
        setStaticValues()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if picturesIds.count == 0 {
            loadDefaultPictures()
        }
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
       // UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        if BLUser.currentUser()!.profileComplete == false && genderIsMale == nil {
            self.chooseGender(self)
        }
    }
    
//    - (UIStatusBarStyle) preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func setupTableView() {
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 124.0
        
        // Header size
        let width = self.view.frame.width - 8
        if var newFrame = tableView.tableHeaderView?.frame {
            newFrame.size.height = (width * (2/3)) + 50
            tableView.tableHeaderView?.frame = newFrame
        }
    }
    func setNavigationBarLayout() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.barTintColor = UIColor.blackColor()
        
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName:UIFont(name: "Montserrat-Bold", size: 18.0)!, NSForegroundColorAttributeName:UIColor.whiteColor()]
        let buttonColor = UIColor(hue: 0.96, saturation: 0.89, brightness: 0.84, alpha: 1)
        self.navigationItem.leftBarButtonItem?.tintColor = buttonColor
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if BLUser.currentUser()!.profileComplete == false {
            self.navigationItem.hidesBackButton = true
            self.title = NSLocalizedString("Create your profile", comment: "")
            self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("Next", comment: "")
           // self.navigationItem.rightBarButtonItem?.tintColor = UIColor.redColor()
        }
        else {
            self.navigationItem.hidesBackButton = false
            self.title = NSLocalizedString("Edit your profile", comment: "")
            self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("Save", comment: "")
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(cancel(_:)))
            
        }
    }
    func setupTextViews() {
        for txtView in self.textViews {
            txtView.delegate = self
        }
    }
    func setStaticValues() {
        if let user = BLUser.currentUser() {
            self.picturesIds = user.currentPictureIds
            self.genderIsMale = user.isMale
            
            var idx = 0
            for txtView in self.textViews {
                txtView.placeholder = ProfileInfoType(rawValue: idx)!.placeholder()
                txtView.text = user.infoForType(ProfileInfoType(rawValue: idx)!)
                idx += 1
            }
        }
    }
    func additionnalSetup() {
        for pView in self.pictureViews {
            pView.delegate = self
        }
    }
    
    func loadDefaultPictures() {
        PicturesManager.getProfilePictureIds { (ids, error) -> Void in
            if ids != nil {
                self.picturesIds = Array(ids!.prefix(3))
                print("picture ids = \(self.picturesIds)")
            }
        }
    }
    
    
    @IBAction func chooseGender(sender: AnyObject) {
        let title = NSLocalizedString("Please specify your gender", comment: "")
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .ActionSheet)
        
        
        let maleAction = UIAlertAction(title: NSLocalizedString("Male", comment: ""), style: .Default) { (action:UIAlertAction) -> Void in
            self.genderIsMale = true
        }
        let femaleAction = UIAlertAction(title: NSLocalizedString("Female", comment: ""), style: .Default) { (action:UIAlertAction) -> Void in
            self.genderIsMale = false
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(maleAction)
        controller.addAction(femaleAction)
        controller.addAction(cancelAction)
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
    func pictureViewDidTapPicture(view: PictureView) {
        let pictureViewIndex = pictureViews.indexOf(view)!
        if pictureViewIndex < 3 {
            self.pictureIndexToChange = pictureViewIndex
            let picker = OLFacebookImagePickerController()
            picker.delegate = self
            picker.shouldDisplayLogoutButton = false
            self.presentViewController(picker, animated: true, completion: nil)
        }
        else if pictureViewIndex < picturesIds.count {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            
            let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: UIAlertActionStyle.Destructive, handler: { (action:UIAlertAction) -> Void in
                self.picturesIds.removeAtIndex(pictureViewIndex)
            })
            let changeAction = UIAlertAction(title: NSLocalizedString("Change", comment: ""), style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction) -> Void in
                self.pictureIndexToChange = pictureViewIndex
                let picker = OLFacebookImagePickerController()
                picker.delegate = self
                picker.shouldDisplayLogoutButton = false
                self.presentViewController(picker, animated: true, completion: nil)
            })
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil)
            
            alertController.addAction(deleteAction)
            alertController.addAction(changeAction)
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            let picker = OLFacebookImagePickerController()
            picker.delegate = self
            picker.shouldDisplayLogoutButton = false
            self.presentViewController(picker, animated: true, completion: nil)
        }
    }
    
    func cancel(sender:AnyObject) {
        if BLUser.currentUser()!.profileComplete == true {
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func saveProfile(sender: AnyObject) {
        if checkProfileValid(true) == false { return }
        self.view.endEditing(false)
        let user = BLUser.currentUser()!
        user.isMale = genderIsMale!
        var idx = 0
        for txtView in self.textViews {
            user.setInfoForType(txtView.text, forType: ProfileInfoType(rawValue: idx)!)
            idx += 1
        }
        
        
        SVProgressHUD.show()
        var saveCount = 0
        for id in picturesIds {
            PicturesManager.sharedInstance.saveFBPictureToParse(id, callback: { (pic, error) in
                if pic != nil { saveCount += 1 }
                if saveCount == self.picturesIds.count {
                    user.currentPictureIds = self.picturesIds
                    user.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) -> Void in
                        SVProgressHUD.dismiss()
                        if success {
                            self.successfullySaved()
                        }
                        else {
                            let errorMessage = NSLocalizedString("Could not save profile...", comment: "")
                            SVProgressHUD.showErrorWithStatus(errorMessage)
                        }
                    })
                }
            })
        }
    }

    
    func successfullySaved() {
        NSNotificationCenter.defaultCenter().postNotificationName("NOTIFICATION_PROFILE_CHANGED", object: nil)
        switch mode {
        case .Create:
            let alertController = UIAlertController(title: NSLocalizedString("Reminder", comment: ""), message: NSLocalizedString("You can always edit your profile in the settings.", comment: ""), preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: NSLocalizedString("Got it!", comment: ""), style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction) -> Void in
                self.performSegueWithIdentifier("DiscoverySettings", sender: self)
               // self.performSegueWithIdentifier("ShowSweat", sender: self)
            })
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
           // showAlert()
            break
        case .Update:
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func showAlert() {
        UIView.animateWithDuration(0.5, animations: {
            self.alertView.frame = CGRect(x: 20, y: 200, width: self.alertView.frame.size.width, height: self.alertView.frame.size.height)
        })
    }
    
    func checkProfileValid(alert:Bool) -> Bool {
        if genderIsMale == nil {
            if alert { SVProgressHUD.showErrorWithStatus(NSLocalizedString("You must specify your gender", comment: "")) }
            return false
        }
        if picturesIds.count < 3 {
            if alert { SVProgressHUD.showErrorWithStatus(NSLocalizedString("A minimum of 3 pictures are required", comment: "")) }
            return false
        }
        return true
    }
    
    // MARK: UITextView Delegate
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let futureLength = textView.text.characters.count - range.length + text.characters.count
        if futureLength > fieldCharacterLimit {
            return false
        }
        
        return true
    }
    
    
    // MARK: Facebook Image Picker Delegate
    
    func facebookImagePicker(imagePicker: OLFacebookImagePickerController!, didFailWithError error: NSError!) {
        pictureIndexToChange = nil
        
        SVProgressHUD.showErrorWithStatus(NSLocalizedString("Picking picture failed", comment: ""))
    }
    func facebookImagePicker(imagePicker: OLFacebookImagePickerController!, shouldSelectImage image: OLFacebookImage!) -> Bool {
        if imagePicker.selected == nil || imagePicker.selected?.count < 1 {
            return true
        }
        else {
            return false
        }
    }
    func facebookImagePickerDidCancelPickingImages(imagePicker: OLFacebookImagePickerController!) {
        pictureIndexToChange = nil
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
    }
    func facebookImagePicker(imagePicker: OLFacebookImagePickerController!, didFinishPickingImages images: [AnyObject]!) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        pictureIndexToChange = nil
    }
    func facebookImagePicker(imagePicker: OLFacebookImagePickerController!, didSelectImage image: OLFacebookImage!) {
        if pictureIndexToChange != nil {
            if pictureIndexToChange >= picturesIds.count {
                picturesIds.append(image.uid)
            }
            else {
                picturesIds[pictureIndexToChange!] = image.uid
                pictureIndexToChange = nil
            }
            
        }
        else {
            picturesIds.append(image.uid)
        }
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DiscoverySettings" {
            let vc = segue.destinationViewController as! DiscoveryPreferencesController
            vc.creatingProfile = true
        }
    }
    
}

