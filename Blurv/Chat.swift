//
//  Chat.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-22.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import Foundation


class Chat:NSObject {
    var id:String!
    var info:ChatInfo!
    var users:[BLUser]?
    
    init(userIds:[String], chatId:String, sourceGameId:String) {
        super.init()
        let chatInfo = ChatInfo(users: userIds, lastActivity: NSDate().timeIntervalSince1970, gameId: sourceGameId)
        self.info = chatInfo
        self.id = chatId
    }
    
    required init?(info:AnyObject, chatId:String) {
        super.init()
        
        self.id = chatId
        if let theInfo = ChatInfo(dictionnary: info) {
            self.info = theInfo
        }
        else {
            return nil
        }
    }
    
    func loadUsers(callback:(success:Bool) -> Void) {
        let ids = Array(self.info.users.keys)
        let expected = ids.count
        var failures = 0
        var userList = [BLUser]()
        
        let check = {
            if failures + userList.count == expected {
                self.users = userList
                callback(success: failures == 0)
            }
        }
        
        for anId in ids {
            BlurvClient.getUserWithId(anId, callback: { (user) in
                if user != nil {
                    userList.append(user!)
                }
                else {
                    failures += 1
                }
                check()
            })
        }
    }
    func otherUsers() -> [BLUser]? {
        if self.users != nil {
            var userList = [BLUser]()
            for aUser in self.users! {
                if aUser.objectId != BLUser.currentUser()?.objectId {
                    userList.append(aUser)
                }
            }
            return userList
        }
        return nil
    }
    func allUsersNames() -> String {
        if let theUsers = self.users {
            var names = [String]()
            for aUser in theUsers {
                names.append(aUser.firstName)
            }
            return names.joinWithSeparator(", ")
        }
        else {
            return ""
        }
    }
    func allOtherUsersName() -> String {
        if let theUsers = self.users {
            var names = [String]()
            for aUser in theUsers {
                if aUser.objectId != BLUser.currentUser()?.objectId {
                    names.append(aUser.firstName)
                }
            }
            return names.joinWithSeparator(", ")
        }
        return ""
    }
    func lastActivityDate() -> NSDate {
        return NSDate(timeIntervalSince1970: self.info.lastActivity)
    }
    func lastActivity() -> NSTimeInterval {
        return self.info.lastActivity
    }
    

    
}
