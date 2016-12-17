//
//  QuestionController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import SVProgressHUD


class QuestionController: BlurvViewController, UITableViewDataSource, UITextViewDelegate {

    @IBOutlet weak var tableView: UITableView!
        
    var game:Game!
    var questionIndex:Int!

    var currentQuestion:Question {
        get {
            return game.questionAtIndex(questionIndex)
        }
    }
    
    var textView:UITextView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(QuestionController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(QuestionController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.textView?.becomeFirstResponder()

    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.tableView.contentInset.bottom = keyboardSize.height + 20
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0), atScrollPosition: UITableViewScrollPosition.None, animated: true)
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.tableView.contentInset.bottom = 0
            self.view.layoutIfNeeded()
        })
    }
    
    
    
    func configureNavigationBar() {
        self.navigationItem.title = String(format: NSLocalizedString("Question %d", comment:""), (questionIndex + 1))
        if currentQuestion.answerForCurrentUser() != nil {
            self.navigationItem.rightBarButtonItem = nil
        }
        else {
            let enabledColor = blurv_color
            let disabledColor = UIColor(hue: 0.6, saturation: 0.08, brightness: 0.7, alpha: 1)
            let enabledAttr = [NSFontAttributeName:UIFont(name: "Montserrat-Bold", size: 18.0)!, NSForegroundColorAttributeName:enabledColor]
            let disabledAttr = [NSFontAttributeName:UIFont(name: "Montserrat-Bold", size: 18.0)!, NSForegroundColorAttributeName:disabledColor]
            self.navigationItem.rightBarButtonItem?.setTitleTextAttributes(enabledAttr, forState: .Normal)
            self.navigationItem.rightBarButtonItem?.setTitleTextAttributes(disabledAttr, forState: .Disabled)
            
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
    }
    
    func addGestureForPictureView(pView:PictureView) {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(QuestionController.showFullPicture(_:)))
        pView.addGestureRecognizer(tapGR)
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("QuestionContentCell", forIndexPath: indexPath) as! QuestionContentCell
            
            cell.questionLabel.text = currentQuestion.localizedContent()
            return cell
        case 1:
            if let otherAnswer = currentQuestion.answerForOtherUser() {
                if currentQuestion.answerForCurrentUser() != nil {
                    let cell = tableView.dequeueReusableCellWithIdentifier("AnswerCell", forIndexPath: indexPath) as! AnswerCell
                    cell.pictureView.pictureId = game.otherUser!.currentPictureIds[questionIndex]
                    cell.pictureView.blur = false
                    addGestureForPictureView(cell.pictureView)
                    cell.statusLabel.text = String(format: NSLocalizedString("answered %@", comment:""), otherAnswer.answeredAt.timeAgo())
                    cell.nameLabel.text = game.otherUser!.firstName
                    cell.answerLabel.text = otherAnswer.content
                    return cell
                }
                else {
                    let cell = tableView.dequeueReusableCellWithIdentifier("UnrevealedAnswerCell", forIndexPath: indexPath) as! UnrevealedAnswerCell
                    cell.pictureView.pictureId = game.otherUser!.currentPictureIds[questionIndex]
                    cell.pictureView.blur = true
                    
                    let lockedImage = UIImage(named: "image_lock")
                    let lockedImageView = UIImageView(image: lockedImage)
                    lockedImageView.frame = CGRect(x:0, y: 0, width: cell.pictureView.frame.width, height: cell.pictureView.frame.width)
                    cell.pictureView.addSubview(lockedImageView)
                    
                    cell.statusLabel.text = String(format: NSLocalizedString("%@ answered %@", comment:""), game.otherUser!.firstName, otherAnswer.answeredAt.timeAgo())
                    return cell
                }
            }
            else {
                let cell = tableView.dequeueReusableCellWithIdentifier("UnrevealedAnswerCell", forIndexPath: indexPath) as! UnrevealedAnswerCell
                cell.pictureView.pictureId = game.otherUser!.currentPictureIds[questionIndex]
                cell.pictureView.blur = true
                
                let lockedImage = UIImage(named: "image_lock")
                let lockedImageView = UIImageView(image: lockedImage)
                lockedImageView.frame = CGRect(x:0, y: 0, width: cell.pictureView.frame.width, height: cell.pictureView.frame.width)
                cell.pictureView.addSubview(lockedImageView)
                
                cell.statusLabel.text = String(format: NSLocalizedString("%@ didn't answer yet", comment:""), game.otherUser!.firstName)
                return cell
            }
        case 2:
            if let myAnswer = currentQuestion.answerForCurrentUser() {
                let cell = tableView.dequeueReusableCellWithIdentifier("AnswerCell", forIndexPath: indexPath) as! AnswerCell
                cell.pictureView.pictureId = BLUser.currentUser()!.currentPictureIds[questionIndex]
                cell.pictureView.blur = false
                addGestureForPictureView(cell.pictureView)
                cell.statusLabel.text = String(format: NSLocalizedString("answered %@", comment:""), myAnswer.answeredAt.timeAgo())
                cell.nameLabel.text = NSLocalizedString("You", comment: "")
                cell.answerLabel.text = myAnswer.content
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCellWithIdentifier("AnswerBoxCell", forIndexPath: indexPath) as! AnswerBoxCell
                cell.textView.delegate = self
                self.textView = cell.textView
                
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
    

    func textViewDidChange(textView: UITextView) {
        if textView.text.characters.count > 0 {
            self.navigationItem.rightBarButtonItem?.enabled = true
        }
        else {
            self.navigationItem.rightBarButtonItem?.enabled = false

        }
    }

    
    @IBAction func sendAnswer(sender: AnyObject) {
        
        if textView?.text.characters.count > 0 {
            if currentQuestion.answerForCurrentUser() == nil {
                SVProgressHUD.show()
                self.navigationController?.popViewControllerAnimated(true)
                GameManager.sharedManager.answer(questionIndex: questionIndex, inGame: game, content: textView!.text, callback: { (success) in
                    SVProgressHUD.dismiss()
                    if success == true {
                        NSNotificationCenter.defaultCenter().postNotificationName("NOTIFICATION_REFRESH_GAME", object: self.game)
                    }
                    else {
                        let errorMessage = NSLocalizedString("Error: Could not send answer...", comment: "")
                        SVProgressHUD.showErrorWithStatus(errorMessage)
                    }
                })
            }
            else {
                let errorMessage = NSLocalizedString("You have already answered this question.", comment: "")
                SVProgressHUD.showErrorWithStatus(errorMessage)
            }
        }
        else {
            let errorMessage = NSLocalizedString("Cannot send empty answer.", comment: "")
            SVProgressHUD.showErrorWithStatus(errorMessage)
        }
        
    }
    
    
    func showFullPicture(sender:UITapGestureRecognizer) {
        if let pView = sender.view as? PictureView {
            let vc = storyboard!.instantiateViewControllerWithIdentifier("PicturePageController") as! PicturePageController
            vc.pictureIds = [pView.pictureId!]
            vc.setInitialIndex(0)
            vc.modalTransitionStyle = .CrossDissolve
            vc.modalPresentationStyle = .OverCurrentContext
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    
}










