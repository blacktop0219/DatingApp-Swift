//
//  BLAdjective.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse


class BLAdjective: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return "Adjective"
    }
    
    @NSManaged var content:String
    @NSManaged var forMale:Bool
    @NSManaged var forFemale:Bool
    @NSManaged var type:String
    
}
