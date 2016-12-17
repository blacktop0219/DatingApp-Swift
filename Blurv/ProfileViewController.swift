//
//  ProfileViewController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-21.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit


class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var picturesScrollView: UIScrollView!
    @IBOutlet weak var picturesPageControl: UIPageControl!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var lastActiveLabel: UILabel!
    
    var fromBrowse = false
    var user:BLUser? = nil
    var blurIndex:Int?
    var mainInfo:[ProfileInfo] = []
    var mutualFriendsInfo:[[NSObject:AnyObject]]?
    var secondaryInfo:[ProfileInfo] = []
    var ternaryInfo:[ProfileInfo] = []
    
    var sections:[String] {
        get {
            var array:[String] = []
            
            if shouldShowMainInfo() { array.append("main") }
            if shouldShowMututalFriends() { array.append("mutual_friends") }
            if shouldShowSecondaryInfo() { array.append("secondary") }
            if shouldShowTernaryInfo() { array.append("ternary") }
            
            return array
        }
    }
    
    var theUser:BLUser {
        return self.user == nil ? BLUser.currentUser()!:self.user!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        configurePicturesScrollView()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if user != nil {
            if fromBrowse {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "more_icon"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ProfileViewController.more))
            }
            else {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        loadPictures()
        loadProfileInfo()
        tableView.reloadData()
        user?.getMutualFriendsList({ (people) -> Void in
            if people != nil {
                self.mutualFriendsInfo = people

                self.tableView.reloadData()
            }
        })
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(0.3) { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    func loadProfileInfo() {
        
        mainInfo = theUser.mainInfo()
        secondaryInfo = theUser.secondaryInfo()
        ternaryInfo = theUser.ternaryInfo()
        
        var navTitle = theUser.firstName
        if let age = theUser.age {
            navTitle += ", \(age)"
        }
        self.navigationItem.title = navTitle
        
        firstNameLabel.text = theUser.firstName
        distanceLabel.text = String(format: NSLocalizedString("%@ away", comment:""), theUser.localizedDistanceFromCurrentLocation())
        let descriptor = theUser.isMale ? NSLocalizedString("Active_Male", comment: "male"):NSLocalizedString("Active_Female", comment: "female")
        lastActiveLabel.text = String(format: NSLocalizedString("%@ %@", comment:"last active (%descriptor %timeAgo)"), descriptor, theUser.lastActivity.timeAgo())
    }
    func configureTableView() {
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    func configurePicturesScrollView() {
        picturesScrollView.delegate = self
        picturesScrollView.pagingEnabled = true
        picturesScrollView.showsHorizontalScrollIndicator = false
    }
    func loadPictures() {
        picturesScrollView.contentOffset = CGPointZero
        for v in picturesScrollView.subviews {
            v.removeFromSuperview()
        }
        let pictureIds = theUser.currentPictureIds
        let p = pictureIds.count
        let n = ((p-1) - ((p-1) % 3))/3 + 1 // PAGE COUNT
        picturesPageControl.numberOfPages = n
        picturesPageControl.currentPage = 0
        
        let radius:CGFloat = 40
        var idx = 0
        for id in pictureIds {
            let pageIndex = CGFloat((idx - (idx % 3))/3)
            
            let t = CGFloat(idx % 3)
            let s = 0.3125*t + 0.1875
            let xCenter = s*self.view.frame.width + (pageIndex * self.view.frame.width)
            
            let x = xCenter-radius
            let y = picturesScrollView.frame.height / 2 - radius
            
            let pView = PictureView(frame: CGRect(x: x, y: y, width: radius*2, height: radius*2))
            pView.tag = idx
            pView.pictureId = id
            if blurIndex != nil {
                pView.blur = idx >= blurIndex!
                if pView.blur == true {
                    let lockedImage = UIImage(named: "image_lock")
                    let lockedImageView = UIImageView(image: lockedImage)
                    lockedImageView.frame = CGRect(x:0, y: 0, width: pView.frame.width, height: pView.frame.width)
                    pView.addSubview(lockedImageView)
                    
                }
            }
            else {
                if self.theUser.objectId == BLUser.currentUser()?.objectId {
                    pView.blur = false
                }
                else {
                    pView.blur = true
                    let lockedImage = UIImage(named: "image_lock")
                    let lockedImageView = UIImageView(image: lockedImage)
                    lockedImageView.frame = CGRect(x:0, y: 0, width: pView.frame.width, height: pView.frame.width)
                    pView.addSubview(lockedImageView)
                }
            }
            if pView.blur == false || fromBrowse {
                let tapGR = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.showFullPicture(_:)))
                pView.addGestureRecognizer(tapGR)
            }
            pView.layer.cornerRadius = radius
            picturesScrollView.addSubview(pView)
            
            idx += 1
        }
        let c = pictureIds.count - 1
        let pageCount = (c - (c % 3)) / 3  + 1
        let fullWidth = CGFloat(pageCount) * self.view.frame.width
        
        picturesScrollView.contentSize = CGSize(width: fullWidth, height: picturesScrollView.frame.height)
    }
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView == picturesScrollView {
            let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
            picturesPageControl.currentPage = Int(pageNumber)
        }
    }
    
    func showFullPicture(sender:UITapGestureRecognizer) {
        if fromBrowse {
            let message = String(format: NSLocalizedString("You have to match with %@ before you can see their pictures.", comment: ""), user!.firstName)
            showLockedHud(message)
        }
        else if let pView = sender.view as? PictureView {
            
            let picVC = storyboard!.instantiateViewControllerWithIdentifier("PicturePageController") as! PicturePageController
            var ids:[String] = []
            if blurIndex != nil {
                ids = Array(theUser.currentPictureIds.prefix(blurIndex!))
            }
            else {
                ids = theUser.currentPictureIds
            }
            picVC.pictureIds = ids
            picVC.setInitialIndex(pView.tag)
            picVC.modalPresentationStyle = .OverCurrentContext
            picVC.modalTransitionStyle = .CrossDissolve
            self.presentViewController(picVC, animated: true, completion: nil)
        }
    }
    
    
    func more() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let reportAction = UIAlertAction(title: String(format: NSLocalizedString("Report %@", comment: ""), self.user!.firstName), style: .Destructive) { (action:UIAlertAction) in
            
            self.promptReport()
            
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil)
        actionSheet.addAction(reportAction)
        actionSheet.addAction(cancelAction)
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func promptReport() {
        let alert = UIAlertController(title: NSLocalizedString("Report", comment: ""), message: String(format: NSLocalizedString("Are you sure you want to report %@?", comment:""), self.user!.firstName), preferredStyle: .Alert)
        let reportAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Destructive) { (action:UIAlertAction) in
            BlurvClient.sharedClient.reportUser(self.user!.objectId!)
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: nil)
        alert.addAction(reportAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.sections.count
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let theSection = self.sections[section]
        
        switch theSection {
        case "main":
            return mainInfoCount()
        case "mutual_friends":
            return 1
        case "secondary":
            return secondaryInfoCount()
        case "ternary":
            return ternaryInfoCount()
        default:
            return 0
        }
    }
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 20)
        let view = UIView(frame: frame)
        view.backgroundColor = UIColor.clearColor()
        return view
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = indexPath.row
        let theSection = self.sections[indexPath.section]
        
        switch theSection {
        case "main":
            let info = mainInfo[row]
            let cell = threadCellForType(info.0, content: info.1, indexPath: indexPath)
            if row == 0 { cell.isFirst = true }
            else { cell.isFirst = false }
            if row == mainInfoCount() - 1 { cell.isLast = true }
            else { cell.isLast = false }
            return cell
            
        case "mutual_friends":
            let cell = tableView.dequeueReusableCellWithIdentifier("MutualFriendsCell", forIndexPath: indexPath) as! MutualFriendsCell
            cell.mutualFriendsInfo = self.mutualFriendsInfo
            return cell
            
        case "secondary":
            let info = secondaryInfo[row]
            let cell = threadCellForType(info.0, content: info.1, indexPath: indexPath)
            if row == 0 { cell.isFirst = true }
            else { cell.isFirst = false }
            if row == secondaryInfoCount() - 1 { cell.isLast = true }
            else { cell.isLast = false }
            return cell
            
        case "ternary":
            let info = ternaryInfo[row]
            let cell = threadCellForType(info.0, content: info.1, indexPath: indexPath)
            if row == 0 { cell.isFirst = true }
            else { cell.isFirst = false }
            if row == ternaryInfoCount() - 1 { cell.isLast = true }
            else { cell.isLast = false }
            return cell
            
        default:
            return UITableViewCell()
        }
    
    }
    func threadCellForType(type:ProfileInfoType, content:String, indexPath:NSIndexPath) -> ProfileThreadCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProfileThreadCell", forIndexPath: indexPath) as! ProfileThreadCell

        cell.fieldType = type
        cell.content = content
        
        return cell
    }
    func mainInfoCount() -> Int {
        return mainInfo.count
    }
    func shouldShowMainInfo() -> Bool {
        return mainInfoCount() > 0
    }
    func secondaryInfoCount() -> Int {
        return secondaryInfo.count
    }
    func shouldShowSecondaryInfo() -> Bool {
        return secondaryInfoCount() > 0
    }
    func ternaryInfoCount() -> Int {
        return ternaryInfo.count
    }
    func shouldShowTernaryInfo() -> Bool {
        return ternaryInfoCount() > 0
    }
    func shouldShowMututalFriends() -> Bool {
        return mutualFriendsInfo?.count > 0
    }
    
    
    
    @IBAction func editProfile(sender: AnyObject) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("EditProfileNavController")
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func showLockedHud(text:String, duration:NSTimeInterval? = nil) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("BLHudController") as! BLHudController
        vc.text = text
        vc.dismissAfter = (duration != nil) ? duration!:1.5
        vc.modalPresentationStyle = .OverCurrentContext
        vc.modalTransitionStyle = .CrossDissolve
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    
    
    
}









