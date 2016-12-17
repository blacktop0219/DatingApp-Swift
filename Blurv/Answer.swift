//
//  Answer.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit

class Answer:NSObject {
    var content:String
    var answeredAt:NSDate
    
    init(content:String) {
        self.content = content
        self.answeredAt = NSDate()
    }
    
    init?(dictionnary:AnyObject) {
        let theContent = dictionnary.objectForKey("content") as? String
        let theTimestamp = dictionnary.objectForKey("answeredAt") as? NSNumber
        
        if theContent != nil && theTimestamp != nil {
            self.content = theContent!
            self.answeredAt = NSDate(timeIntervalSince1970: theTimestamp!.doubleValue)
        }
        else {
            return nil
        }
    }
    
    func toDictionnary() -> [String:AnyObject] {
        var dict = [String:AnyObject]()
        dict["content"] = self.content
        dict["answeredAt"] = NSNumber(double: self.answeredAt.timeIntervalSince1970)
        
        return dict
    }
}


