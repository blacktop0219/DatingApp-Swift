//
//  FeedManager.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-14.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse

enum FeedUserState {
    case Like, Dislike, NotDetermined
}

typealias FeedUser = (user:BLUser, picture:UIImage, state:FeedUserState)

protocol FeedManagerDelegate {
    func feedManagerDidStartLoadingFeed(manager:FeedManager)
    func feedManagerDidLoadFeed(manager:FeedManager, isEmpty:Bool)
    func feedManagerDidClearFeed(manager:FeedManager)
    func feedManager(manager:FeedManager, undoStateChanged canUndo:Bool)
    func feedManager(manager:FeedManager, skipStateChanged canSkip:Bool)
}


class FeedManager: NSObject {

    static let sharedManager = FeedManager()
    
    private(set) var feed:[FeedUser] = [] {
        didSet {
            let oldCanSkip = oldValue.count > 1
            let newCanSkip = feed.count > 1
            if oldCanSkip != newCanSkip {
                delegate?.feedManager(self, skipStateChanged: newCanSkip)
            }
        }
    }
    private var lastDislikedUser:FeedUser? {
        didSet {
            if lastDislikedUser != nil {
                delegate?.feedManager(self, undoStateChanged: true)
            }
            else {
                delegate?.feedManager(self, undoStateChanged: false)
            }
        }
    }
    
    var delegate:FeedManagerDelegate?
    
    var shouldClear:Bool = false
    
    override init() {
        super.init()
        
        setupNotificationObservers()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC)*0.1)), dispatch_get_main_queue()) { () -> Void in
            self.loadFeed()
        }
    }
    private func setupNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserverForName("NOTIFICATION_DISCOVERY_CHANGED", object: nil, queue: nil) { (notif:NSNotification) in
            self.shouldClear = true
            self.clearFeedAndReloadIfNeeded()
            self.loadFeed()
        }
        NSNotificationCenter.defaultCenter().addObserverForName("NOTIFICATION_LOCATION_CHANGED", object: nil, queue: nil) { (notif:NSNotification) in
            if self.isFeedEmpty() { self.loadFeed() }
        }
    }
    
    func loadFeedIfNeeded() -> Bool {
        if self.feed.count == 0 {
            self.loadFeed()
            return true
        }
        return false
    }
    func isFeedEmpty() -> Bool {
        return self.feed.count == 0
    }
    
    private func loadFeed() {
        if let currentUser = BLUser.currentUser(), currentUserAge = BLUser.currentUser()?.age, currentLocation = BlurvClient.sharedClient.locationManager.location {
            if !currentUser.profileComplete { return }
            delegate?.feedManagerDidStartLoadingFeed(self)
            BlurvClient.sharedClient.setActiveNow(false)
            
            let query1 = BLUser.query()!
            let query2 = BLUser.query()!
            query2.whereKey("discoverGender", equalTo: 2)
            
            if currentUser.isMale {
                query1.whereKey("discoverGender", equalTo: 0)
            }
            else {
                query1.whereKey("discoverGender", equalTo: 1)
            }
            
            let likes = currentUser.relationForKey("likes").query()
            let dislikes = currentUser.relationForKey("dislikes").query()
            
            let pastInteractions = PFQuery.orQueryWithSubqueries([likes, dislikes])
            
            let theQuery = PFQuery.orQueryWithSubqueries([query1, query2])
            theQuery.whereKey("objectId", doesNotMatchKey: "objectId", inQuery: pastInteractions)
            theQuery.whereKey("objectId", notEqualTo: currentUser.objectId!)
            theQuery.whereKey("discoveryAgeMin", lessThanOrEqualTo: currentUserAge)
            theQuery.whereKey("discoveryAgeMax", greaterThanOrEqualTo: currentUserAge)
            
            theQuery.whereKey("lastPosition", nearGeoPoint: PFGeoPoint(location: currentLocation), withinKilometers: Double(currentUser.discoveryDistance))
            
            let now = NSDate()
            let ageMax = currentUser.discoveryAgeMax
            let ageMin = currentUser.discoveryAgeMin
            let minBirthdate = now.dateByAddingTimeInterval(-Double(ageMax) * TIME_INTERVAL_YEAR)
            let maxBirthdate = now.dateByAddingTimeInterval(-Double(ageMin) * TIME_INTERVAL_YEAR)
            
            theQuery.whereKey("birthdate", greaterThanOrEqualTo: minBirthdate)
            theQuery.whereKey("birthdate", lessThanOrEqualTo: maxBirthdate)
            
            if currentUser.discoverGender == 0 {
                theQuery.whereKey("isMale", equalTo: true)
            }
            else if currentUser.discoverGender == 1 {
                theQuery.whereKey("isMale", equalTo: false)
            }
            
            theQuery.limit = 20
            
            theQuery.findObjectsInBackgroundWithBlock { (results:[PFObject]?, error:NSError?) -> Void in
                if results?.count > 0 {
                    let users = results as! [BLUser]
                    
                    var theFeed:[FeedUser] = []
                    let expected = users.count
                    var failures = 0
                    
                    let check = {
                        if theFeed.count + failures == expected {
                            self.feed = theFeed
                            self.delegate?.feedManagerDidLoadFeed(self, isEmpty: false)
                        }
                    }
                    for aUser in results as! [BLUser] {
                        aUser.pinInBackground()
                        PicturesManager.sharedInstance.getFeedPictureForUser(aUser, callback: { (picture) in
                            if picture != nil {
                                theFeed.append((aUser, picture!, .NotDetermined))
                            }
                            else {
                                failures += 1
                            }
                            check()
                        })
                    }
                }
                else {
                    self.feed = []
                    self.delegate?.feedManagerDidLoadFeed(self, isEmpty: true)
                }
            }
        }
        else {
            self.delegate?.feedManagerDidLoadFeed(self, isEmpty: true)
        }
    }
    
    func clearFeedAndReloadIfNeeded() {
        if shouldClear {
            feed = []
            delegate?.feedManagerDidClearFeed(self)
            shouldClear = false
            self.loadFeed()
        }
    }
    func sendUserToBack(index:Int) -> Bool {
        if self.feed.count > 1 {
            feed.append(feed.removeAtIndex(index))
            var idx = 0
            for aUser in feed {
                if aUser.state != .NotDetermined {
                    feed.removeAtIndex(idx)
                }
                else {
                    idx += 1
                }
            }
            return true
        }
        return false
    }
    func canUndoLastDislike() -> Bool {
        return self.lastDislikedUser != nil
    }
    func undo(callback:(success:Bool) -> Void) {
        if let feedUser = self.lastDislikedUser, currentUser = BLUser.currentUser() {
            currentUser.dislikes.removeObject(feedUser.user)
            currentUser.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) in
                if success {
                    self.lastDislikedUser = nil
                }
                callback(success: success)
            })
        }
        else {
            callback(success: false)
        }
    }
    func dislikeAtIndex(index:Int, callback:((success:Bool) -> Void)? = nil) {
        if feed.count == 0 { return }
        BlurvClient.sharedClient.setActiveNow(true)
        
        if let currentUser = BLUser.currentUser() {
            let user = self.feed[index].user
            
            checkForInteraction(user.objectId!) { (exists, error) in
                if error == nil && exists == false {
                    self.feed[index].state = .Dislike
                    self.lastDislikedUser = self.feed[index]
                    
                    currentUser.dislikes.addObject(user)
                    currentUser.saveInBackgroundWithBlock { (success:Bool, error:NSError?) -> Void in
                        self.clearFeedAndReloadIfNeeded()
                        if error == nil {
                            callback?(success: true)
                        }
                        else {
                            callback?(success: false)
                        }
                    }
                }
                else {
                    callback?(success: false)
                }
            }
        }
        else {
            callback?(success: false)
        }
    }
    func likeAtIndex(index:Int, callback:((success:Bool) -> Void)? = nil) {
        if self.feed.count == 0 { return }
        BlurvClient.sharedClient.setActiveNow(true)
        let user = self.feed[index].user
        
        if let currentUser = BLUser.currentUser() {
            checkForInteraction(user.objectId!) { (exists, error) in
                if error == nil && exists == false {
                    // proceed
                    self.feed[index].state = .Like
                    self.lastDislikedUser = nil
                    
                    currentUser.likes.addObject(user)
                    currentUser.saveInBackgroundWithBlock { (success:Bool, error:NSError?) -> Void in
                        self.clearFeedAndReloadIfNeeded()
                        if error == nil {
                            // Check for a match
                            let otherUserLikes = user.likes.query()
                            otherUserLikes.whereKey("objectId", equalTo: currentUser.objectId!)
                            otherUserLikes.countObjectsInBackgroundWithBlock({ (count:Int32, error:NSError?) -> Void in
                                if error == nil {
                                    callback?(success: true)
                                    if count > 0 {
                                        let ids = [currentUser.objectId!, user.objectId!]
                                        GameManager.sharedManager.createGame(ids)
                                    }
                                }
                            })
                        }
                        else {
                            print("Error saving user while liking user")
                            callback?(success: false)
                        }
                    }
                }
                else {
                    callback?(success: false)
                }
            }
        }
        else {
            callback?(success: false)
        }
        
    }
    
    
    func checkForInteraction(userId:String, callback:(exists:Bool, error:NSError?) -> Void) {
        let currentUser = BLUser.currentUser()!
        let likeQuery = currentUser.likes.query()
        let dislikeQuery = currentUser.dislikes.query()
        let interactionQuery = PFQuery.orQueryWithSubqueries([likeQuery, dislikeQuery])
        interactionQuery.whereKey("objectId", equalTo: userId)
        interactionQuery.findObjectsInBackgroundWithBlock { (results:[PFObject]?, error:NSError?) in
            if error == nil {
                callback(exists: results?.count > 0, error: nil)
            }
            else {
                callback(exists: true, error: error)
            }
        }
    }
    
    
}






