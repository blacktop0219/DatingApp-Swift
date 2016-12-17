//
//  ChatController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-03.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

class ChatController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, ChatObserver {

    let defaultBottomInset:CGFloat = 10
    
    @IBOutlet weak var inputBottom: NSLayoutConstraint!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputContainer: UIView!
    @IBOutlet weak var textView: CustomTextView!
   // @IBOutlet weak var navPictureView: PictureView!
    @IBOutlet weak var navTitleLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    let textAttributes = [NSFontAttributeName:UIFont(name: "Montserrat-Regular", size: 16.0)!]
    
    var chat:Chat!
    
    var user:BLUser? {
        return chat.otherUsers()?.first
    }
    
    var messages:[ChatMessage] {
        return ChatManager.sharedManager.messagesForChatId(chat.id)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNotificationObservers()
        configureTextView()
        
        let userAge = user?.age
        self.navTitleLabel.text = (user?.firstName)! + ", " + String(userAge!)
       // self.navPictureView.pictureId = user?.currentPictureIds.first
        
        if let titleView = navigationItem.titleView {
            let tapGR = UITapGestureRecognizer(target: self, action: #selector(ChatController.showFullProfile(_:)))
            titleView.addGestureRecognizer(tapGR)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        adjustTextView()
        textView.becomeFirstResponder()
        ChatManager.sharedManager.addObserverForChatId(self, chatId: chat.id)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationManager.sharedManager.readNotificationsForChatWithId(chat.id)
        NotificationManager.sharedManager.readNotificationsForGameWithId(chat.info.gameId)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationManager.sharedManager.readNotificationsForChatWithId(chat.id)
        if let gameId = chat.info.gameId {
            NotificationManager.sharedManager.readNotificationsForGameWithId(gameId)
        }
        ChatManager.sharedManager.removeObserverForChatId(self, chatId: chat.id)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    func setupNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatController.keyboardWillChange(_:)), name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatController.pop), name: "CHAT_REMOVED_" + chat.id, object: nil)
    }
    
    func pop() {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func configureTextView() {
        sendButton.enabled = false
        textView.delegate = self
        textView.placeholder = NSLocalizedString("Type your message here...", comment: "Chat textview placeholder")
    }
    
    func adjustTextView() {
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        
        textViewHeight.constant = newSize.height
        self.view.layoutIfNeeded()
    }
    
    func scrollToBottom(animated:Bool) {
        if messages.count > 0 {
            let rect = CGRect(x: 0, y: self.tableView.contentSize.height - self.tableView.bounds.size.height, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height)
            self.tableView.scrollRectToVisible(rect, animated: animated)
        }
    }
    
    func scrollToLastMessage(animated:Bool) {
        if messages.count > 0 {
            let indexPath = NSIndexPath(forRow: messages.count - 1, inSection: 0)
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.None, animated: animated)
        }
    }
    
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.inputBottom.constant = keyboardSize.height
                    self.view.layoutIfNeeded()
                    self.scrollToBottom(false)
                })
            }
        }
    }
    
    func keyboardWillChange(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            UIView.animateWithDuration(0.2, animations: { 
                self.inputBottom.constant = keyboardSize.height
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.inputBottom.constant = 0
            self.view.layoutIfNeeded()
        })
    }
    
    
    // MARK: ACTIONS
    
    
    
    @IBAction func sendMessage(sender: AnyObject) {
        let sanitized = textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if sanitized.characters.count > 0 {
            ChatManager.sharedManager.sendMessage(chat, content: sanitized)
            textView.text = ""
            adjustTextView()
        }
    }
    
    func promptReport() {
        if let otherUser = chat.otherUsers()?.first {
            let alertTitle = String(format: NSLocalizedString("Report %@", comment:""), otherUser.firstName)
            let alertMessage = String(format: NSLocalizedString("Are you sure you want to report %@?", comment:""), otherUser.firstName)
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
            let confirmAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Destructive, handler: { (action:UIAlertAction) -> Void in
                BlurvClient.sharedClient.reportUser(otherUser.objectId!, inChat: self.chat)
                SVProgressHUD.showSuccessWithStatus(NSLocalizedString("Your report has been sent.", comment: ""))
                self.navigationController?.popViewControllerAnimated(true)
            })
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil)
            
            alert.addAction(confirmAction)
            alert.addAction(cancelAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func promptUnmatch() {
        let name = chat.otherUsers()!.first!.firstName
        let alertTitle = String(format: NSLocalizedString("Unmatch %@", comment: ""), name)
        let alertMessage = String(format: NSLocalizedString("Are you sure you want to unmatch %@? You will no longer be able to contact each other.", comment: ""), chat.otherUsers()!.first!.firstName)
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        let confirmAction = UIAlertAction(title: NSLocalizedString("Unmatch", comment: ""), style: UIAlertActionStyle.Destructive) { (action:UIAlertAction) in
            BlurvClient.sharedClient.unmatchFromChat(self.chat, callback: { (success) in
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
    
    func showFullProfile(sender:AnyObject) {
        let profileVC = storyboard?.instantiateViewControllerWithIdentifier("ProfileController") as! ProfileViewController
        profileVC.user = chat.otherUsers()?.first
        profileVC.blurIndex = Int.max
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    @IBAction func showOptions(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let title = String(format: NSLocalizedString("See %@'s profile", comment:""), user!.firstName)
        let seeProfileAction = UIAlertAction(title: title, style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
            self.showFullProfile(self)
        }
        let reportTitle = String(format: NSLocalizedString("Report %@", comment:""), user!.firstName)
        let reportAction = UIAlertAction(title: reportTitle, style: .Destructive) { (action:UIAlertAction) -> Void in
            self.promptReport()
        }
        let unmatchAction = UIAlertAction(title: String(format: NSLocalizedString("Unmatch %@", comment: ""), chat.otherUsers()!.first!.firstName), style: .Destructive) { (action:UIAlertAction) in
            self.promptUnmatch()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.Cancel, handler: nil)
        
        actionSheet.addAction(seeProfileAction)
        actionSheet.addAction(reportAction)
        actionSheet.addAction(unmatchAction)
        actionSheet.addAction(cancelAction)
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    // MARK: TEXTVIEW
    func textViewDidChange(textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        
        textViewHeight.constant = newSize.height
        self.view.layoutIfNeeded()
    
        sendButton.enabled = textView.text.characters.count > 0
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        print("should end")
        return true
    }

    // MARK: Chat Observer

    func chatDidReceiveNewMessage(message: ChatMessage, atIndex index: Int) {
        if index > messages.count { return }
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        let animation:UITableViewRowAnimation = (message.userId == BLUser.currentUser()!.objectId) ? .Right:.Left
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { 
            self.scrollToLastMessage(true)
        }
        
        tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: animation)
        tableView.endUpdates()
        CATransaction.commit()
        
        if self.view.window != nil {
            NotificationManager.sharedManager.readNotificationsForChatWithId(self.chat.id)
        }
    }
    
    
    // MARK: TABLEVIEW
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        var identifier = ""
        if message.userId == BLUser.currentUser()!.objectId {
            identifier = "OutgoingMessageCell"
        }
        else {
            identifier = "IncomingMessageCell"
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! ChatMessageCell
        
        cell.messageLabel.text = message.body
        if message.userId == BLUser.currentUser()!.objectId {
          //  cell.messagePicture.pictureId = BLUser.currentUser()!.currentPictureIds.first
        }
        else {
            cell.messagePicture.pictureId = user?.currentPictureIds.first
        }
        
        
        return cell
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let text = messages[indexPath.row].body
        
        let maxSize = CGSize(width: self.tableView.bounds.width - 86, height: CGFloat.max)
        let rect = NSString(string: text).boundingRectWithSize(maxSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: self.textAttributes, context: nil)
        return rect.height + 29
    }
    
}
















