//
//  ChatUser.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-22.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import Foundation

class ChatUser:NSObject {
    var id:String!
    var unread:Bool!
    var out:Bool!
    
    init(id:String) {
        self.id = id
        unread = true
        out = false
    }
    
    convenience init(dictionnary:AnyObject, userId:String) {
        self.init(id: userId)
        
        let theUnread = dictionnary.objectForKey("unread") as? Bool
        let theOut = dictionnary.objectForKey("out") as? Bool
        
        if theUnread != nil {
            self.unread = theUnread
        }
        
        if theOut != nil {
            self.out = theOut!
        }
    }
    
    func toDictionnary() -> AnyObject {
        var dict = [String:AnyObject]()
        dict["placeholder"] = true
        dict["unread"] = self.unread
        dict["out"] = self.out
        return dict
    }
}

