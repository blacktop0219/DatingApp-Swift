//
//  BLReport.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-03-10.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse

class BLReport: PFObject, PFSubclassing {
    
    static func parseClassName() -> String {
        return "Report"
    }
    
    @NSManaged var userId:String
    @NSManaged var meta:String
}
