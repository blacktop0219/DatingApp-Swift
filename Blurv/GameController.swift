//
//  GameController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

class GameController: BlurvViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, GameObserver {

    @IBOutlet weak var picturesScrollView: UIScrollView!
    @IBOutlet weak var picturesPageControl: UIPageControl!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var lastActiveLabel: UILabel!
    @IBOutlet weak var navTitleButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBOutlet weak var alertView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    
    var game:Game!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameController.pop), name: "GAME_REMOVED_" + game.id, object: nil)
        
        setupTableView()
        populatePicturesScrollView()
        loadUserData()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        GameManager.sharedManager.addObserver(self, forGameId: game.id!)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.clearSelection(animated)
        showAlert()
        NotificationManager.sharedManager.readNotificationsForGameWithId(game.id!)
        NotificationManager.sharedManager.scheduleReminderForQuestion(game.currentQuestionIndex(), inGame: game)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        GameManager.sharedManager.removeObserver(self, forGameId: game.id)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: Setup/Loading
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    func loadUserData() {
        let otherUser = game.otherUser!
        self.distanceLabel.text = String(format: NSLocalizedString("%@ away", comment:""), otherUser.localizedDistanceFromCurrentLocation())
        
        var text:String = "Active \(otherUser.lastActivity.timeAgo())"
        if BlurvClient.languageShortCode() == "fr" {
            let descriptor = otherUser.isMale ? "Actif":"Active"
            text = "\(descriptor) \(otherUser.lastActivity.timeAgo())"
        }
        lastActiveLabel.text = text
        
        var navTitle = otherUser.firstName
        if let age = otherUser.age {
            navTitle += ", \(age)"
        }
        navTitleButton.setTitle(navTitle, forState: .Normal)
    }
    
    func showAlert() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let checkedGame = defaults.stringForKey("checkedGame")
        if checkedGame == nil || checkedGame!.isEmpty {
            self.nameLabel.text = game.otherUser!.firstName
            self.alertView.hidden = false
        }
    }
    
    // MARK: Game Manager Observer

    func gameDidChange(id: String, newGame: Game) {
        if game.id == id {
            self.game = newGame
            for i in 0..<4 {
                configureCell(nil, index: i, animated: true)
            }

            updatePicturesBlurState()
            NotificationManager.sharedManager.readNotificationsForGameWithId(game.id)
        }
    }
    
    func pop() {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    
    
    // MARK: External Game Update
    
    func setUpdatedGame(newGame:Game) {
        self.game = newGame
        tableView.reloadData()
        updatePicturesBlurState()
    }
    
    // MARK: Table View
    
    func configureCell(cell:GameStepCell? = nil, index:Int, animated:Bool) {
        if let theCell = cell ?? self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? GameStepCell {
            if index < 3 {
                let qStatus = game.statusForQuestionIndex(index)
                theCell.setStatus(qStatus, animated: animated, withDelay: animated ? (Double(index) * 0.5):0)
                
                theCell.statusLabel.text = game.statusDescriptionForQuestionIndex(index)
                
                switch qStatus {
                case .Locked:
                    theCell.titleLabel.text = String(format: NSLocalizedString("Question %d", comment:""), (index + 1))
                    theCell.descriptionLabel.text = ""
                default:
                    theCell.titleLabel.text = String(format: NSLocalizedString("Q %d", comment:""), (index + 1))
                    theCell.descriptionLabel.text = game.questionAtIndex(index).localizedContent()
                }
            }
            else {
                theCell.titleLabel.text = String(format: NSLocalizedString("Free chat with %@", comment:""), game.otherUser!.firstName)
                theCell.descriptionLabel.text = ""
                var status = ""
                if game.complete() {
                    if game.currentUserReadyForChat() && game.otherUserReadyForChat() {
                        status = NSLocalizedString("You are both ready to chat", comment: "")
                        theCell.setStatus(QuestionStatus.Complete, animated: animated, withDelay: 0)
                    }
                    else if game.currentUserReadyForChat() {
                        status = String(format: NSLocalizedString("%@ is not ready to chat yet", comment: ""), game.otherUser!.firstName)
                        theCell.setStatus(QuestionStatus.Incomplete, animated: animated, withDelay: 0)
                    }
                    else {
                        status = NSLocalizedString("Are you ready to chat?", comment: "")
                        theCell.setStatus(QuestionStatus.Incomplete, animated: animated, withDelay: 0)
                    }
                }
                else {
                    status = NSLocalizedString("Unlock with previous questions", comment: "")
                    theCell.setStatus(QuestionStatus.Locked, animated: animated, withDelay: 0)
                }
                theCell.statusLabel.text = status
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //if stepCells.count == 4 { stepCells = [] }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("GameStepCell", forIndexPath: indexPath) as! GameStepCell
        
        let row = indexPath.row
        if row == 0 { cell.isFirst = true }
        if row == 3 { cell.isLast = true }
        
        
        configureCell(cell, index: indexPath.row, animated: false)
        
        //stepCells.append(cell)
        
        return cell
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.row == 3 {
            if !game.complete() {
                let errorMessage = NSLocalizedString("Unlock chat with previous questions", comment: "")
                self.showLockedHud(errorMessage)
                return false
            }
            else {
                if game.currentUserReadyForChat() {
                    if game.otherUserReadyForChat() {
                        return true
                    }
                    else {
                        let errorMessage = String(format: NSLocalizedString("%@ is not ready to chat yet", comment: ""), game.otherUser!.firstName)
                        self.showLockedHud(errorMessage)
                        return false
                    }
                }
                else {
                    return true
                }
            }
        }
        else {
            let status = game.statusForQuestionIndex(indexPath.row)
            switch status {
            case .Locked, .Invalid:
                let message = NSLocalizedString("Unlock with previous questions", comment: "")
                self.showLockedHud(message)
                return false
            default:
                return true
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 3 {
            if !game.currentUserReadyForChat() {
               // AppDelegate.showChatUnlocked(game)
                GameManager.sharedManager.setReadyForChat(game)
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
            else {
                if let chatId = game.chatId {
                    ChatManager.sharedManager.getChatWithId(chatId, callback: { (chat) in
                        if chat != nil {
                            self.pushToChat(chat!)
                        }
                    })
                }
                else {
                    GameManager.sharedManager.setReadyForChat(game)
                }
            }
        }
        else {
            self.pushToQuestionWithIndex(indexPath.row)
        }
    }
    
    
    
    func clearSelection(animated:Bool) {
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selected, animated: animated)
        }
    }


    
    // MARK: Actions
    
    func promptReport() {
        let alert = UIAlertController(title: String(format: NSLocalizedString("Report %@", comment:""), self.game.otherUser!.firstName), message: String(format: NSLocalizedString("Are you sure you want to report %@?", comment:""), self.game.otherUser!.firstName), preferredStyle: .Alert)
        let confirmAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Destructive, handler: { (action:UIAlertAction) -> Void in
            BlurvClient.sharedClient.reportUser(self.game.otherUser!.objectId!, inGame: self.game)
            SVProgressHUD.showSuccessWithStatus(NSLocalizedString("Your report has been sent.", comment: ""))
            self.navigationController?.popViewControllerAnimated(true)
        })
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil)

        alert.addAction(confirmAction)
        alert.addAction(cancelAction)

        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func promptUnmatch() {
        let alert = UIAlertController(title: String(format: NSLocalizedString("Unmatch %@", comment: ""), self.game.otherUser!.firstName), message: String(format: NSLocalizedString("Are you sure you want to unmatch %@? You will no longer be able to contact each other.", comment: ""), game.otherUser!.firstName), preferredStyle: UIAlertControllerStyle.Alert)
        let confirmAction = UIAlertAction(title: NSLocalizedString("Unmatch", comment: ""), style: UIAlertActionStyle.Destructive) { (action:UIAlertAction) in
            BlurvClient.sharedClient.unmatchFromGame(self.game, callback: { (success) in
                if success {
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
                else {
                    SVProgressHUD.showErrorWithStatus(NSLocalizedString("Could not unmatch. Please try again later.", comment: ""))
                }
            })
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func showFullProfile(sender:AnyObject) {
        let profileVC = storyboard?.instantiateViewControllerWithIdentifier("ProfileController") as! ProfileViewController
        profileVC.user = game.otherUser!
        profileVC.blurIndex = game.complete() ? Int.max:game.currentQuestionIndex()
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    
    @IBAction func showOptions(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let seeProfileAction = UIAlertAction(title: String(format: NSLocalizedString("See %@'s profile", comment:""), game.otherUser!.firstName), style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
            self.showFullProfile(self)
        }
        let unmatchAction = UIAlertAction(title: String(format: NSLocalizedString("Unmatch %@", comment: ""), game.otherUser!.firstName), style: .Destructive) { (action:UIAlertAction) in
            self.promptUnmatch()
        }
        let reportAction = UIAlertAction(title: String(format: NSLocalizedString("Report %@", comment:""), game.otherUser!.firstName)
        , style: .Destructive) { (action:UIAlertAction) -> Void in
            self.promptReport()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil)
        
        actionSheet.addAction(seeProfileAction)
        actionSheet.addAction(reportAction)
        actionSheet.addAction(unmatchAction)
        actionSheet.addAction(cancelAction)
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    @IBAction func closeAlertView(sender: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject("checked", forKey: "checkedGame")
        
        self.alertView.hidden = true
    }
    
    // MARK: Navigation
    func pushToQuestionWithIndex(index:Int) {
        let status = game.statusForQuestionIndex(index)
        if status != .Locked {
            let questionVC = storyboard?.instantiateViewControllerWithIdentifier("QuestionController") as! QuestionController
            questionVC.game = self.game
            questionVC.questionIndex = index
            self.navigationController?.pushViewController(questionVC, animated: true)
        }
    }
    
    func pushToChat(chat:Chat) {
        if game.chatId != nil {
            let chatController = storyboard!.instantiateViewControllerWithIdentifier("ChatController") as! ChatController
            chatController.chat = chat
            self.navigationController?.pushViewController(chatController, animated: true)
        }
    }
    
    
    // MARK: Pictures
    func addGestureForPictureView(pView:PictureView) {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(GameController.pictureViewTapped(_:)))
        tapGR.delegate = self
        pView.addGestureRecognizer(tapGR)
    }
    
    func populatePicturesScrollView() {
        
        picturesScrollView.delegate = self
        
        let theUser = game.otherUser!
        
        // Clear if already populated
        if picturesScrollView.subviews.count > 0 {
            for v in picturesScrollView.subviews {
                v.removeFromSuperview()
            }
        }
        
        picturesScrollView.contentOffset = CGPointZero

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
            pView.blur = game.complete() ? false:idx >= game.currentQuestionIndex()
            
            if pView.blur {
                let lockedImage = UIImage(named: "image_lock")
                let lockedImageView = UIImageView(image: lockedImage)
                lockedImageView.frame = CGRect(x:0, y: 0, width: radius*2, height: radius*2)
                pView.addSubview(lockedImageView)
            }
            self.addGestureForPictureView(pView)
            pView.layer.cornerRadius = radius
            picturesScrollView.addSubview(pView)
            
            idx += 1
        }
        let c = pictureIds.count - 1
        let pageCount = (c - (c % 3)) / 3  + 1
        let fullWidth = CGFloat(pageCount) * self.view.frame.width
        
        picturesScrollView.contentSize = CGSize(width: fullWidth, height: picturesScrollView.frame.height)
    }
    
    func updatePicturesBlurState() {
        for pView in picturesScrollView.subviews {
            if let pictureView = pView as? PictureView {
                let newBlur = game.complete() ? false:pictureView.tag >= game.currentQuestionIndex()
                
                if newBlur != pictureView.blur {
                    pictureView.blur = newBlur                    
                    if newBlur == false {
                        let lockedImage = pictureView.imageView.image
                        let lockedImageView = UIImageView(image: lockedImage)
                        lockedImageView.frame = CGRect(x:0, y: 0, width: 40*2, height: 40*2)
                        pictureView.addSubview(lockedImageView)
                    }
                }

            }
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if scrollView == picturesScrollView {
            let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
            picturesPageControl.currentPage = Int(pageNumber)
        }
    }
    
    func pictureViewTapped(sender:UITapGestureRecognizer) {
        if let pView = sender.view as? PictureView {
            let tappedIndex = pView.tag
            let currentIndex = game.currentQuestionIndex()
            if game.complete() || tappedIndex < currentIndex {
                self.showPicture(tappedIndex)
            }
            else {
                if tappedIndex > 2 {
                    let errorMessage = String(format: NSLocalizedString("You and %@ have to answer all the questions before this picture is unblurred", comment:""), game.otherUser!.firstName)
                    showLockedHud(errorMessage, duration: 3.0)
                }
                else if game.questionAtIndex(currentIndex).noAnswers() {
                    let errorMessage = String(format: NSLocalizedString("You and %@ have to answer question %d before this picture is unblurred", comment:""), game.otherUser!.firstName, (tappedIndex + 1))
                    showLockedHud(errorMessage, duration: 3.0)
                }
                else if game.questionAtIndex(currentIndex).answerForCurrentUser() == nil {
                    let errorMessage = String(format: NSLocalizedString("You have to answer question %d before this picture is unblurred", comment:""), (tappedIndex + 1))
                    showLockedHud(errorMessage, duration: 3.0)
                }
                else {
                    let errorMessage = String(format: NSLocalizedString("%@ has to answer %d before this picture is unblurred", comment:""), game.otherUser!.firstName, (tappedIndex + 1))
                    showLockedHud(errorMessage, duration: 3.0)
                }
            }
        }
    }
    
    func showPicture(index:Int) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("PicturePageController") as! PicturePageController
        var ids:[String] = []
        if game.complete() {
            ids = game.otherUser!.currentPictureIds
        }
        else {
            ids = Array(game.otherUser!.currentPictureIds.prefix(game.currentQuestionIndex()))
        }
        vc.pictureIds = ids
        vc.setInitialIndex(index)
        vc.modalPresentationStyle = .OverCurrentContext
        vc.modalTransitionStyle = .CrossDissolve
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    
    
    
    // MARK: Utility
    
    func showLockedHud(text:String, duration:NSTimeInterval? = nil) {
        SVProgressHUD.dismiss()
        let vc = storyboard!.instantiateViewControllerWithIdentifier("BLHudController") as! BLHudController
        vc.text = text
        vc.dismissAfter = (duration != nil) ? duration!:1.5
        vc.modalPresentationStyle = .OverCurrentContext
        vc.modalTransitionStyle = .CrossDissolve
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
}















