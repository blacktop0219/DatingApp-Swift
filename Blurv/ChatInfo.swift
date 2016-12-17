//
//  ChatInfo.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-22.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import Foundation

struct ChatInfo {
    var lastActivity:NSTimeInterval
    var users:[String:ChatUser]
    var gameId:String!
    var lastMessage:ChatMessage?
    
    init(users:[String], lastActivity:NSTimeInterval, gameId:String) {
        var theUsers = [String:ChatUser]()
        for anId in users {
            let aUser = ChatUser(id: anId)
            theUsers[anId] = aUser
        }
        self.gameId = gameId
        self.users = theUsers
        self.lastActivity = lastActivity
    }
    
    init?(dictionnary:AnyObject) {
        
        let timestamp = dictionnary["lastActivity"] as? NSNumber
        let theUsers = dictionnary["users"] as? [String:AnyObject]
        let theLastMessage = dictionnary["lastMessage"] as? [String:AnyObject]
        let gameId = dictionnary["gameId"] as? String
        
        if timestamp != nil && theUsers != nil && gameId != nil {
            self.lastActivity = timestamp!.doubleValue
            var userList = [String:ChatUser]()
            for (userId, value) in theUsers! {
                let user = ChatUser(dictionnary: value, userId: userId)
                userList[userId] = user
            }
            self.users = userList
            self.gameId = gameId!
            if let messageId = theLastMessage?["id"] as? String {
                self.lastMessage = ChatMessage(dictionnary: theLastMessage!, id: messageId)
            }
        }
        else {
            return nil
        }
    }
    
    func toDictionnary() -> AnyObject {
        var dict = [String:AnyObject]()
        dict["lastActivity"] = NSNumber(double: self.lastActivity)
        var userList = [String:AnyObject]()
        for (userId, chatUser) in self.users {
            userList[userId] = chatUser.toDictionnary()
        }
        
        dict["users"] = userList
        dict["lastMessage"] = self.lastMessage?.toDictionnaryWithEmbedId()
        dict["gameId"] = self.gameId
        return dict
    }
    
    func otherUsersIds() -> [String] {
        var userIds = Array(self.users.keys)
        for anId in userIds {
            if anId == BLUser.currentUser()?.objectId {
                userIds.removeAtIndex(userIds.indexOf(anId)!)
                break
            }
        }
        return userIds
    }
    
    func userIsOut(userId:String) -> Bool {
        return users[userId]?.out ?? true
    }
}