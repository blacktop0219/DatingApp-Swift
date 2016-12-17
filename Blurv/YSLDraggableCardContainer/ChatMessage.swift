//
//  ChatMessage.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-22.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import Foundation

class ChatMessage:NSObject {
    var id:String!
    var body:String!
    var userId:String!
    var timestamp:NSTimeInterval!
    
    init(body:String, userId:String, messageId:String, timestamp:Double) {
        self.body = body
        self.userId = userId
        self.id = messageId
        self.timestamp = timestamp
    }
    
    convenience init?(dictionnary:AnyObject, id:String) {
        if !(dictionnary is [String:AnyObject]) { return nil }
        let theBody = dictionnary.objectForKey("body") as? String
        let theUserId = dictionnary.objectForKey("userId") as? String
        let theTimestamp = dictionnary.objectForKey("timestamp") as? NSNumber
        
        if theBody != nil && theUserId != nil && theTimestamp != nil {
            self.init(body: theBody!, userId: theUserId!, messageId: id, timestamp: theTimestamp!.doubleValue)
        }
        else {
            return nil
        }
    }
    
    func toDictionnary() -> AnyObject {
        var dict = [String:AnyObject]()
        dict["body"] = self.body
        dict["userId"] = self.userId
        dict["timestamp"] = NSNumber(double: self.timestamp)
        return dict
    }
    func toDictionnaryWithEmbedId() -> AnyObject {
        var dict = self.toDictionnary() as! [String:AnyObject]
        dict["id"] = self.id
        return dict
    }
    
    override var description: String {
        return "\(self.body) : \(String(Int32(self.timestamp)))"
    }
}