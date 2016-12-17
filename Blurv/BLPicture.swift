//
//  BLPicture.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-19.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse


class BLPicture: PFObject, PFSubclassing {

    override class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    static func parseClassName() -> String {
        return "Picture"
    }
    
    @NSManaged var pictureId:String
    @NSManaged var user:BLUser
    @NSManaged var file:PFFile
}
