//
//  Question.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit


class Question:NSObject {
    let id:String
    var content_en:String
    var content_fr:String
    var answers:[String:Answer]
    var users:[String:AnyObject]
    
    init(fromStaticQuestion aQuestion:StaticQuestion, userIds:[String]) {
        self.id = aQuestion.objectId!
        self.content_en = aQuestion.content_en
        self.content_fr = aQuestion.content_fr
        self.answers = [:]
        
        var theUsers:[String:AnyObject] = [:]
        for aUser in userIds {
            let info = ["reminderScheduled":false]
            theUsers[aUser] = info
        }
        self.users = theUsers
    }
    
    init?(dictionnary:AnyObject) {
        let theId = dictionnary.objectForKey("id") as? String
        let theContentFR = dictionnary.objectForKey("content_fr") as? String
        let theContentEN = dictionnary.objectForKey("content_en") as? String
        let theAnswers = dictionnary.objectForKey("answers") as? [String:AnyObject]
        let theUsers = dictionnary.objectForKey("users") as? [String:AnyObject]
        
        if theId != nil && theContentEN != nil && theContentFR != nil && theUsers != nil {
            self.id = theId!
            self.content_fr = theContentFR!
            self.content_en = theContentEN!
            self.users = theUsers!
            
            if theAnswers != nil {
                self.answers = [:]
                for (userId, answerDict) in theAnswers! {
                    self.answers[userId] = Answer(dictionnary: answerDict)
                }
            }
            else {
                self.answers = [:]
            }
        }
        else {
            return nil
        }
    }
    
    func toDictionnary() -> [String:AnyObject] {
        var dict = [String:AnyObject]()
        dict["id"] = self.id
        dict["content_fr"] = self.content_fr
        dict["content_en"] = self.content_en
        dict["users"] = self.users
        
        var theAnswers = [String:AnyObject]()
        for (userId, answer) in self.answers {
            theAnswers[userId] = answer.toDictionnary()
        }
        dict["answers"] = theAnswers
        
        return dict
    }
    
    func setAnswerForCurrentUser(content:String) -> Answer? {
        if let currentUser = BLUser.currentUser() {
            let answer = Answer(content: content)
            self.answers[currentUser.objectId!] = answer
            return answer
        }
        else {
            return nil
        }
    }
    func noAnswers() -> Bool {
        return self.answers.count == 0
    }
    func answerForCurrentUser() -> Answer? {
        if let currentUser = BLUser.currentUser() {
            let answer = self.answers[currentUser.objectId!]
            return answer
        }
        return nil
    }
    func answerForOtherUser() -> Answer? {
        if let currentUser = BLUser.currentUser() {
            for (userId, anAnswer) in answers {
                if userId != currentUser.objectId! {
                    return anAnswer
                }
            }
        }
        return nil
    }
    func reminderScheduled() -> Bool {
        if let currentUser = BLUser.currentUser() {
            if let userInfo = self.users[currentUser.objectId!] {
                return userInfo["reminderScheduled"] as! Bool
            }
            return true
        }
        return true
    }
    func localizedContent() -> String? {
        let lang = BlurvClient.languageShortCode()
        if lang == "fr" {
            return self.content_fr
        }
        else {
            return self.content_en
        }
    }
}

