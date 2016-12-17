//
//  BLPhrase.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse


class BLPhrase: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return "Phrase"
    }
    
    @NSManaged var content:String
    @NSManaged var type:String
    @NSManaged var forMale:Bool
    @NSManaged var forFemale:Bool
    
}
