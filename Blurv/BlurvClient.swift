//
//  BlurvClient.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-25.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse
import CoreLocation
import Firebase
import FBSDKLoginKit

let TIME_INTERVAL_YEAR:NSTimeInterval = 365.25*24*60*60

typealias LocationUpdateCallback = () -> Void

class BlurvClient: NSObject, CLLocationManagerDelegate {
    static let sharedClient = BlurvClient()
    
    let firebaseRef = Firebase(url: "https://blurv.firebaseio.com/")
    let usersRef = Firebase(url: "https://blurv.firebaseio.com/users")
    
    let locationManager = CLLocationManager()
    
    let dateFormatter = NSDateFormatter()
    
    var lastActiveUpdate:NSDate = NSDate().dateByAddingTimeInterval(-100000000)
    var lastLocationUpdate:NSDate = NSDate().dateByAddingTimeInterval(-100000000)
    
    var adjectives_male:[BLAdjective] = []
    var phrases_male_new_picture:[BLPhrase] = []
    var phrases_male_chatUnlocked:[BLPhrase] = []
    var adjectives_female:[BLAdjective] = []
    var phrases_female_new_picture:[BLPhrase] = []
    var phrases_female_chatUnlocked:[BLPhrase] = []
    
    var questionBank:[String:StaticQuestion] = [:]
    
    private var loadingDone = false {
        didSet {
            if loadingDone {
               // GameManager.sharedManager.showNewMatchIfNeeded()
            }
        }
    }
    
    class func appLoaded() -> Bool {
        return BlurvClient.sharedClient.loadingDone
    }
    class func setAppLoaded() {
        BlurvClient.sharedClient.loadingDone = true
    }

    
    class func getTime(callback:(time:NSDate?) -> Void) {
        PFCloud.callFunctionInBackground("getCurrentTime", withParameters: nil) { (result:AnyObject?, error:NSError?) in
            callback(time: result as? NSDate)
        }
    }
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.distanceFilter = 200
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        let defaultAdjective = BLAdjective()
        defaultAdjective.content = NSLocalizedString("amazing", comment: "default adjective")
        defaultAdjective.forFemale = true
        defaultAdjective.forMale = true
        defaultAdjective.type = "any"
        
        let chatUnlockedPhrase = BLPhrase()
        chatUnlockedPhrase.content = NSLocalizedString("You did it!", comment: "default phrase for chat_unlocked")
        chatUnlockedPhrase.forMale = true
        chatUnlockedPhrase.forFemale = true
        chatUnlockedPhrase.type = "chat_unlocked"
        
        let newPicturePhrase = BLPhrase()
        newPicturePhrase.content = NSLocalizedString("You deserve it!", comment: "default phrase for new_picture")
        newPicturePhrase.forFemale = true
        newPicturePhrase.forMale = true
        newPicturePhrase.type = "new_picture"
        
        adjectives_male = [defaultAdjective]
        adjectives_female = [defaultAdjective]
        phrases_male_chatUnlocked = [chatUnlockedPhrase]
        phrases_male_new_picture = [newPicturePhrase]
        phrases_female_chatUnlocked = [chatUnlockedPhrase]
        phrases_female_new_picture = [newPicturePhrase]
    }
    
    func firebaseLogin(callback:(success:Bool) -> Void) {
        if let fbToken = FBSDKAccessToken.currentAccessToken() {
            firebaseRef.authWithOAuthProvider("facebook", token: fbToken.tokenString, withCompletionBlock: { (error:NSError!, auth:FAuthData!) in
                if error == nil {
                    self.firebaseCreatePaths()
                    GameManager.sharedManager.start()
                    ChatManager.sharedManager.setUserId(BLUser.currentUser()!.objectId!)
                    callback(success: true)
                }
                else {
                    callback(success: false)
                }
            })
        }
        else {
            callback(success: false)
        }
    }
    
    func firebaseCreatePaths() {
        if let user = BLUser.currentUser() {
            let games = Firebase(url: "https://blurv.firebaseio.com/users/\(user.objectId!)").childByAppendingPath("games")
            games.childByAppendingPath("+").setValue(true)
            let chats = Firebase(url: "https://blurv.firebaseio.com/users/\(user.objectId!)").childByAppendingPath("chats")
            chats.childByAppendingPath("+").setValue(true)
        }
    }
    
    func loadAllRequiredItems(done:() -> Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            
            if let user = BLUser.currentUser() {
                do {
                    try user.fetch()
                    user.lang = BlurvClient.languageShortCode()
                    user.saveEventually()
                    NotificationManager.sharedManager.fetchAllUnread()
                }
                catch let error as NSError {
                    print("error fetching user: \(error.localizedDescription)")
                    BLUser.logOut()
                }
            }
            
            self.loadAdjectivesAndPhrases()
            let success = self.loadQuestionBank()
            
            dispatch_async(dispatch_get_main_queue(), {
                if success {
                    done()
                }
            })
        }
    }
    
    
    class func getAppStoreTrackId(callback:(id:String?) -> Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
            let bundleId = AppDelegate.bundleId()
            let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)"
            let data = NSData(contentsOfURL: NSURL(string: urlString)!)
            if data != nil {
                dispatch_async(dispatch_get_main_queue(), { 
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
                        if let results = json.objectForKey("results") as? [AnyObject] {
                            if results.count > 0 {
                                let firstResult = results.first
                                let trackId = firstResult?.objectForKey("trackId") as? String
                                callback(id: trackId)
                            }
                            else { callback(id: nil) }
                        }
                        else { callback(id: nil) }
                    }
                    catch let error as NSError {
                        print("Error parsing json data: \(error)")
                        callback(id: nil)
                    }
                })
            }
            else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(id: nil)
                })
            }
        }
    }
    
    class func appStoreLinkWithAppId(id:String?) -> String? {
        if id == nil { return nil }
        return "http://itunes.apple.com/app/id\(id)?mt=8"
    }
    
    class func rateAppLinkWithAppId(id:String?) -> String? {
        if id == nil { return nil }
        return "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(id)&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
    }
    
    class func languageShortCode() -> String {
        var lang = "en"
        if let preferredLanguage = NSLocale.preferredLanguages().first {
            lang = preferredLanguage.substringToIndex(lang.startIndex.advancedBy(2))
        }
        return lang
    }
    
    class func getUserWithId(userId:String, callback:(user:BLUser?) -> Void) {
        let networkQuery = BLUser.query()!
        networkQuery.whereKey("objectId", equalTo: userId)
        networkQuery.findObjectsInBackgroundWithBlock({ (results:[PFObject]?, error:NSError?) in
            callback(user: results?.first as? BLUser)
        })
    }
    
    func checkReports(callback:(blocked:Bool?, user:BLUser?, error:NSError?) -> Void) {
        if let theUser = BLUser.currentUser() {
            let query = BLReport.query()!
            query.whereKey("userId", equalTo: theUser.objectId!)
            query.countObjectsInBackgroundWithBlock({ (count:Int32, error:NSError?) in
                if error == nil {
                    if count >= 5 {
                        BLUser.logOut()
                        callback(blocked: true, user: theUser, error: nil)
                    }
                    else {
                        callback(blocked: false, user: nil, error: nil)
                    }
                }
                else {
                    callback(blocked: nil, user: nil, error: error)
                }
            })
        }
        else {
            callback(blocked: false, user: nil, error: nil)
        }
    }
    
    func unmatchFromGame(game:Game, callback:(success:Bool) -> Void) {
        let gameId = game.id
        let chatId = game.chatId
        
        NotificationManager.sharedManager.readAllGameNotificationsBeforeUnmatch(gameId) { (success) in
            if success {
                if chatId != nil {
                    NotificationManager.sharedManager.readAllChatNotificationsBeforeUnmatch(chatId!, callback: { (success) in
                        if success {
                            for aUserId in game.users.keys {
                                self.firebaseRef.childByAppendingPath("users/" + aUserId + "/games/" + game.id).removeValue()
                                self.firebaseRef.childByAppendingPath("users/" + aUserId + "/chats/" + chatId!).removeValue()
                            }
                        }
                        else {
                            callback(success: false)
                        }
                    })
                }
                else {
                    for aUserId in game.users.keys {
                        self.firebaseRef.childByAppendingPath("users/" + aUserId + "/games/" + game.id).removeValue()
                    }
                }
            }
            else {
                callback(success: false)
            }
        }
    }
    
    func unmatchFromChat(chat:Chat, callback:(success:Bool) -> Void) {
        let chatId = chat.id
        let gameId = chat.info.gameId
        
        NotificationManager.sharedManager.readAllGameNotificationsBeforeUnmatch(gameId) { (success) in
            if success {
                if chatId != nil {
                    NotificationManager.sharedManager.readAllChatNotificationsBeforeUnmatch(chatId!, callback: { (success) in
                        if success {
                            for aUserId in chat.info.users.keys {
                                self.firebaseRef.childByAppendingPath("users/" + aUserId + "/games/" + gameId).removeValue()
                                self.firebaseRef.childByAppendingPath("users/" + aUserId + "/chats/" + chatId).removeValue()
                            }
                        }
                        else {
                            callback(success: false)
                        }
                    })
                }
                else {
                    for aUserId in chat.info.users.keys {
                        self.firebaseRef.childByAppendingPath("users/" + aUserId + "/games/" + chatId).removeValue()
                    }
                }
            }
            else {
                callback(success: false)
            }
        }
    }
    
    func reportUser(userId:String, inGame game:Game) {
        let meta = "{\"gameId\":\"\(game.id)\"}"
        let report = BLReport()
        report.userId = userId
        report.meta = meta
        report.saveInBackground()
    }
    func reportUser(userId:String, inChat chat:Chat) {
        let meta = "{\"chatId\":\"\(chat.id)\"}"
        let report = BLReport()
        report.userId = userId
        report.meta = meta
        report.saveInBackground()
    }
    func reportUser(userId:String) {
        let meta = "{}"
        let report = BLReport()
        report.userId = userId
        report.meta = meta
        report.saveInBackground()
    }

    
    func startLocationManager() {
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse { locationManager.startUpdatingLocation() }
        else { locationManager.requestWhenInUseAuthorization() }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        NSNotificationCenter.defaultCenter().postNotificationName(NOTIFICATION_LOCATION_SERVICES_STATUS, object: nil)
        switch status {
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    func setNeedsLocationUpdate(force:Bool) {
        if fabs(lastLocationUpdate.timeIntervalSinceNow) > 5*60 || force {
            self.locationManager.startUpdatingLocation()
        }
    }
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentUser = BLUser.currentUser() {
            if let location = locations.first {
                currentUser.lastPosition = PFGeoPoint(location: location)
                currentUser.saveInBackground()
                lastLocationUpdate = NSDate()
                NSNotificationCenter.defaultCenter().postNotificationName("NOTIFICATION_LOCATION_CHANGED", object: nil)
            }
        }
    }
    func setActiveNow(force:Bool) {
        if let currentUser = BLUser.currentUser() {
            if fabs(lastActiveUpdate.timeIntervalSinceNow) > 5*60 || force {
                currentUser.lastActivity = NSDate()
                currentUser.saveInBackground()
                lastActiveUpdate = NSDate()
            }
        }
    }
    
    func getRandomAdjective(genderIsMale:Bool) -> BLAdjective {
        if genderIsMale {
            let random = Int.randRange(0, upper: adjectives_male.count - 1)
            return adjectives_male[random]
        }
        else {
            let random = Int.randRange(0, upper: adjectives_female.count - 1)
            return adjectives_female[random]
        }
    }
    func getRandomPhraseWithType(type:String, genderIsMale:Bool) -> BLPhrase {
        if genderIsMale {
            if type == "chat_unlocked" {
                let random = Int.randRange(0, upper: phrases_male_chatUnlocked.count - 1)
                return phrases_male_chatUnlocked[random]
            }
            else {
                let random = Int.randRange(0, upper: phrases_male_new_picture.count - 1)
                return phrases_male_new_picture[random]
            }
        }
        else {
            if type == "chat_unlocked" {
                let random = Int.randRange(0, upper: phrases_female_chatUnlocked.count - 1)
                return phrases_female_chatUnlocked[random]
            }
            else {
                let random = Int.randRange(0, upper: phrases_female_new_picture.count - 1)
                return phrases_female_new_picture[random]
            }
        }
    }
    func loadQuestionBank() -> Bool {
        let query = StaticQuestion.query()!
        do {
            let results = try query.findObjects()
            for aQuestion in results {
                self.questionBank[aQuestion.objectId!] = aQuestion as? StaticQuestion
            }
            return true
        }
        catch let error as NSError {
            print("error fetching questions: \(error.localizedDescription)")
            return false
        }
    }
    func randomQuestions(count:Int) -> [StaticQuestion] {
        var list:[StaticQuestion] = []
        var alreadyDone:[Int] = [-1]
        for _ in 0..<count {
            var rand = 0
            repeat {
                rand = Int.randRange(0, upper: self.questionBank.count - 1)
            } while alreadyDone.contains(rand)
            alreadyDone.append(rand)
            list.append(Array(questionBank.values)[rand])
        }
        return list
    }
    func loadAdjectivesAndPhrases() {
        let adjectivesQuery = BLAdjective.query()!
        adjectivesQuery.whereKey("lang", equalTo: BlurvClient.languageShortCode())
        
        let phrasesQuery = BLPhrase.query()!
        phrasesQuery.whereKey("lang", equalTo: BlurvClient.languageShortCode())
        
        
        do {
            let adjectives = try adjectivesQuery.findObjects() as! [BLAdjective]
            let phrases = try phrasesQuery.findObjects() as! [BLPhrase]
            
            for adj in adjectives {
                if adj.forMale {
                    self.adjectives_male.append(adj)
                }
                else {
                    self.adjectives_female.append(adj)
                }
            }
            
            for phr in phrases {
                if phr.forMale {
                    if phr.type == "chat_unlocked" {
                        self.phrases_male_chatUnlocked.append(phr)
                    }
                    else {
                        self.phrases_male_new_picture.append(phr)
                    }
                }
                else {
                    if phr.type == "chat_unlocked" {
                        self.phrases_female_chatUnlocked.append(phr)
                    }
                    else {
                        self.phrases_female_new_picture.append(phr)
                    }
                }
            }
            
        }
        catch let error as NSError {
            print("error loading adjectives and phrases: \(error.localizedDescription)")
            return
        }
    }
    


    
    
    
    
    
    

    
}
