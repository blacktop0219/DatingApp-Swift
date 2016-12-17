//
//  StaticQuestion.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-15.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse

class StaticQuestion: PFObject, PFSubclassing {
    static func parseClassName() -> String {
        return "Question"
    }
    
    @NSManaged var content_en:String
    @NSManaged var content_fr:String
}
