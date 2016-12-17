//
//  BLNotification.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-26.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse


class BLNotification: PFObject, PFSubclassing {
    
    static func parseClassName() -> String {
        return "Notification"
    }
    
    @NSManaged var fromId:String
    @NSManaged var toId:String
    @NSManaged var type:String
    @NSManaged var meta:String
    @NSManaged var read:Bool
    @NSManaged var alertKey:String
    @NSManaged var alertArguments:String
    
    var gameId:String? {
        if let gameId = self.metadata?["gameId"] as? String {
            return gameId
        }
        return nil
    }
    var chatId:String? {
        if let chatId = self.metadata?["chatId"] as? String {
            return chatId
        }
        return nil
    }
    
    var questionIndex:Int? {
        if let index = self.metadata?["questionIndex"] as? Int {
            return index
        }
        return nil
    }
    
    var metadata:AnyObject? {
        if self["meta"] != nil {
            if self.meta.characters.count > 2 {
                do {
                    if let data = self.meta.dataUsingEncoding(NSUTF8StringEncoding) {
                        let obj = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                        return obj
                    }
                }
                catch {
                    return nil
                }
            }
        }
        return nil
    }
    var arguments:[AnyObject]? {
        if let args = self["alertArguments"] as? String {
            if args.characters.count > 2 {
                do {
                    if let data = args.dataUsingEncoding(NSUTF8StringEncoding) {
                        let obj = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                        return obj as? [AnyObject]
                    }
                }
                catch {
                    return nil
                }
            }
        }
        return nil
    }
    
    func markAsRead() {
        self.read = true
        self.saveInBackground()
    }
    
    
    
}
