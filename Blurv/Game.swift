//
//  Game.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit


class Game:NSObject {
    // persisted
    var questions:[Question]!
    var lastActivity:NSTimeInterval!
    var users:[String:AnyObject]!
    var chatId:String?
    
    // local
    var id:String!
    var otherUser:BLUser?
   // var chat:Chat?
    
    convenience init(userIds:[String], id:String) {
        self.init()
        self.id = id
        let timestamp = NSDate().timeIntervalSince1970
        let staticQuestions = BlurvClient.sharedClient.randomQuestions(3)
        var list:[Question] = []
        for q in staticQuestions {
            let aQuestion = Question(fromStaticQuestion: q, userIds: userIds)
            list.append(aQuestion)
        }
        self.questions = list
        self.lastActivity = timestamp
        var theUsers = [String:AnyObject]()
        for aUserId in userIds {
            theUsers[aUserId] = [
                "readyForChat":false,
                "newMatch":true,
                "poppedUp":false,
                "unread":true,
                "out":false
            ]
        }
        self.users = theUsers
        self.chatId = nil
    }
    
    convenience init?(dictionnary:AnyObject, gameId:String) {
        self.init()
        
        if !(dictionnary is NSDictionary) { return nil }
        if let theQuestions = dictionnary.objectForKey("questions") as? [AnyObject], timestamp = dictionnary.objectForKey("lastActivity") as? NSNumber, theUsers = dictionnary.objectForKey("users") as? [String:AnyObject] {
            var list:[Question] = []
            for aQ in theQuestions {
                if let theQuestion = Question(dictionnary: aQ) {
                    list.append(theQuestion)
                }
                else {
                    return nil
                }
            }
            lastActivity = timestamp.doubleValue
            questions = list
            id = gameId
            users = theUsers
            
            if let chatId = dictionnary.objectForKey("chatId") as? String {
                self.chatId = chatId
            }
        }
        else {
            return nil
        }
    }
    
    func toDictionnary() -> [String:AnyObject] {
        var dict = [String:AnyObject]()
        var questionArray:[AnyObject] = []
        for aQuestion in questions {
            questionArray.append(aQuestion.toDictionnary())
        }
        dict["questions"] = questionArray
        dict["lastActivity"] = NSNumber(double: self.lastActivity)
        dict["users"] = self.users
        if self.chatId != nil {
            dict["chatId"] = self.chatId!
        }
        return dict
    }
    
    func otherUserId() -> String? {
        if let currentUser = BLUser.currentUser() {
            for (key, _) in users {
                if key != currentUser.objectId! {
                    return key
                }
            }
        }
        return nil
    }
    
    func currentQuestionIndex() -> Int {
        var index = 0
        for aQuestion in questions {
            if aQuestion.answers.count < 2 {
                return index
            }
            index += 1
        }
        return 2
    }
    func currentQuestion() -> Question {
        let index = currentQuestionIndex()
        return questionAtIndex(index)
    }
    func statusDescriptionForQuestionIndex(index:Int) -> String {
        switch statusForQuestionIndex(index) {
        case .Locked, .Invalid:
            return NSLocalizedString("Unlock with previous questions", comment: "")
        case .Incomplete:
            if questionAtIndex(index).noAnswers() {
                return NSLocalizedString("Neither of you have answered yet", comment: "")
            }
            else if questionAtIndex(index).answerForOtherUser() != nil {
                return String(format: NSLocalizedString("%@ is waiting for your answer", comment:""), self.otherUser!.firstName)
            }
            else {
                return String(format: NSLocalizedString("You answered question %d", comment:""), self.currentQuestionIndex() + 1)
            }
        case .Complete:
            return String(format: NSLocalizedString("You and %@ answered", comment:""), self.otherUser!.firstName)
        }
    }
    func statusDescription() -> String {
        if self.complete() {
            if currentUserReadyForChat() && otherUserReadyForChat() {
                return NSLocalizedString("You are both ready to chat", comment: "")
            }
            else if currentUserReadyForChat() {
                return NSLocalizedString("You are ready to chat", comment: "")
            }
            else {
                return NSLocalizedString("Are you ready to chat?", comment: "")
            }
        }
        else {
            if answerCountForQuestionAtIndex(currentQuestionIndex()) == 0 {
                return currentQuestion().localizedContent()!
            }
            else {
                return statusDescriptionForQuestionIndex(currentQuestionIndex())
            }
        }
    }
    
    func statusForQuestionIndex(index:Int) -> QuestionStatus {
        if index > 2 { print("Invalid question status"); return .Invalid }
        if index > currentQuestionIndex() {
            return .Locked
        }
        else {
            let count = self.answerCountForQuestionAtIndex(index)
            if count >= 2 {
                return .Complete
            }
            else {
                return .Incomplete
            }
        }
    }
    func questionAtIndex(index:Int) -> Question {
        if index > 2 { return self.questions[2] }
        return self.questions[index]
    }
    func answerCountForQuestionAtIndex(index:Int) -> Int {
        return self.questionAtIndex(index).answers.count
    }
    
    func complete() -> Bool {
        return (self.currentQuestionIndex() == 2 && statusForQuestionIndex(2) == .Complete)
    }
    
//    func unread() -> Bool {
//        if let user = BLUser.currentUser() {
//            if let userStatus = users[user.objectId!] {
//                return userStatus["unread"] as! Bool
//            }
//        }
//        return false
//    }
    
    func isNewMatch() -> Bool {
        if let user = BLUser.currentUser() {
            if let userStatus = users[user.objectId!] {
                return userStatus["newMatch"] as? Bool ?? false
            }
        }
        return false
    }
    func newMatchPoppedUp() -> Bool {
        if let user = BLUser.currentUser() {
            if let userStatus = users[user.objectId!] {
                return userStatus["poppedUp"] as? Bool ?? true
            }
        }
        return false
    }
    func currentUserReadyForChat() -> Bool {
        if let user = BLUser.currentUser() {
            if let userStatus = users[user.objectId!] {
                return (userStatus.objectForKey("readyForChat") as? Bool) ?? false
            }
        }
        return false
    }
    func otherUserReadyForChat() -> Bool {
        if let user = otherUser {
            if let userStatus = users[user.objectId!] {
                return (userStatus.objectForKey("readyForChat") as? Bool) ?? false
            }
        }
        return false
    }
    
    func loadOtherUser(callback:(success:Bool) -> Void) {
        if let id = self.otherUserId() {
            BlurvClient.getUserWithId(id, callback: { (user) in
                if user != nil {
                    self.otherUser = user!
                    callback(success: true)
                }
                else {
                    callback(success: false)
                }
            })
        }
        else {
            callback(success: false)
        }
    }
    
    func otherUserIsOut() -> Bool {
        if let user = otherUser {
            if let userStatus = users[user.objectId!] {
                return userStatus["out"] as! Bool
            }
        }
        return true
    }
}








