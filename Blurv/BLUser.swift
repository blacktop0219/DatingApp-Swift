//
//  BLUser.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-01-18.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse
import FBSDKCoreKit

typealias ProfileInfo = (infoType:ProfileInfoType, content:String)

enum ProfileInfoType:Int {
    case
    Language,
    LookingFor,
    Question,
    Quote,
    Work,
    Education,
    Children,
    Ethnicity,
    Music,
    About,
    None
    
    func placeholder() -> String {
        switch self {
        case .Language:
            return NSLocalizedString("profile_placeholder_language", comment: "")
        case .LookingFor:
            return NSLocalizedString("profile_placeholder_lookingfor", comment: "")
        case .Question:
            return NSLocalizedString("profile_placeholder_question", comment: "")
        case .Quote:
            return NSLocalizedString("profile_placeholder_quote", comment: "")
        case .Work:
            return NSLocalizedString("profile_placeholder_work", comment: "")
        case .Education:
            return NSLocalizedString("profile_placeholder_education", comment: "")
        case .Children:
            return NSLocalizedString("profile_placeholder_children", comment: "")
        case .Ethnicity:
            return NSLocalizedString("profile_placeholder_ethnicity", comment: "")
        case .Music:
            return NSLocalizedString("profile_placeholder_music", comment: "")
        case .About:
            return NSLocalizedString("profile_placeholder_about", comment: "")
        case .None:
            return ""
        }

    }
    
    func icon(filled:Bool) -> UIImage {
        var name = ""
        switch self {
        case .Language:
            name = "language"
        case .LookingFor:
            name = "looking"
        case .Question:
            name = "question"
        case .Quote:
            name = "quote"
        case .Work:
            name = "work"
        case .Education:
            name = "education"
        case .Children:
            name = "children"
        case .Ethnicity:
            name = "ethnicity"
        case .Music:
            name = "music"
        case .About:
            name = "feather"
        case .None:
            return UIImage()
        }
        
        name += "_icon"
        if filled { name += "_filled" }
        
        if let image = UIImage(named: name) {
            return image
        }
        else {
            return UIImage()
        }
    }
    
}

class BLUser: PFUser {
    
    // Basic
    @NSManaged var firstName:String
    @NSManaged var lastName:String
    @NSManaged var name:String
    @NSManaged var facebookId:String
    @NSManaged var isMale:Bool
    @NSManaged var currentPictureIds:[String]
    @NSManaged var profileComplete:Bool
    @NSManaged var birthdate:NSDate
    
    // Profile
    @NSManaged var language:String
    @NSManaged var about:String
    @NSManaged var lookingFor:String
    @NSManaged var favoriteQuestion:String
    @NSManaged var ethnicity:String
    @NSManaged var music:String
    @NSManaged var children:String
    @NSManaged var quote:String
    @NSManaged var work:String
    @NSManaged var education:String
    
    // Discovery preferences
    @NSManaged var discoverGender:Int // 0=Male, 1=Female, 2=Both
    @NSManaged var discoveryDistance:Int
    @NSManaged var discoveryAgeMin:Int
    @NSManaged var discoveryAgeMax:Int
    
    // App Settings
    @NSManaged var notifyNewMatch:Bool
    @NSManaged var notifyNewAnswer:Bool
    @NSManaged var notifyNewMessage:Bool
    @NSManaged var notifyNewQuestion:Bool
    @NSManaged var lang:String
    
    @NSManaged var lastActivity:NSDate
    @NSManaged var lastPosition:PFGeoPoint
    
    var mutualFriendsInfo:[NSObject:AnyObject]?
    
    
    // Interactions
    var likes:PFRelation {
        return self.relationForKey("likes")
    }
    var dislikes:PFRelation {
        return self.relationForKey("dislikes")
    }
    
    
    var age:Int? {
        if let birthday = self["birthdate"] as? NSDate {
            let interval = fabs(birthday.timeIntervalSinceNow)
            let years = interval / (60*60*24*365.25)
            let age = Int(floor(years))
            return age
        }
        else {
            return nil
        }
    }
    func distanceFromCurrentLocation() -> Double {
        if let currentPosition = BLUser.currentUser()!["lastPosition"] as? PFGeoPoint {
            if let otherPosition = self["lastPosition"] as? PFGeoPoint {
                let currentLocation = CLLocation(latitude: currentPosition.latitude, longitude: currentPosition.longitude)
                let otherLocation = CLLocation(latitude: otherPosition.latitude, longitude: otherPosition.longitude)
                let distance = currentLocation.distanceFromLocation(otherLocation)
                return distance
            }
        }
        return 0
    }
    func localizedDistanceFromCurrentLocation() -> String {
        let distance = self.distanceFromCurrentLocation()
        
        if distance < 100 {
            return "100m"
        }
        else if distance < 500 {
            return "500m"
        }
        else if distance < 1000 {
            return "1km"
        }
        else {
            return "\(Int(round(distance / 1000)))km"
        }
    }
    
    func setInfoForType(info:String, forType type:ProfileInfoType) {
        switch type {
        case .Language:
            self.language = info
        case .LookingFor:
            self.lookingFor = info
        case .Question:
            self.favoriteQuestion = info
        case .Quote:
            self.quote = info
        case .Work:
            self.work = info
        case .Education:
            self.education = info
        case .Children:
            self.children = info
        case .Ethnicity:
            self.ethnicity = info
        case .Music:
            self.music = info
        case .About:
            self.about = info
        case .None:
            break
        }
    }
    
    func infoForType(type:ProfileInfoType) -> String {
        switch type {
        case .Language:
            return self.language
        case .LookingFor:
            return self.lookingFor
        case .Question:
            return self.favoriteQuestion
        case .Quote:
            return self.quote
        case .Work:
            return self.work
        case .Education:
            return self.education
        case .Children:
            return self.children
        case .Ethnicity:
            return self.ethnicity
        case .Music:
            return self.music
        case .About:
            return self.about
        case .None:
            return ""
        }
    }
    
    func mainInfo() -> [ProfileInfo] {
        var info:[ProfileInfo] = []
        
        if self.language.characters.count > 0 {
            info.append((infoType:.Language, content:self.language))
        }

        if self.lookingFor.characters.count > 0 {
            info.append((infoType:.LookingFor, content:self.lookingFor))
        }
        if self.favoriteQuestion.characters.count > 0 {
            info.append((infoType:.Question, content:self.favoriteQuestion))
        }
        if self.quote.characters.count > 0 {
            info.append((infoType:.Quote, content:self.quote))
        }
        
        return info
    }
    func secondaryInfo() -> [ProfileInfo] {
        var info:[ProfileInfo] = []

        if self.work.characters.count > 0 {
            info.append((infoType:.Work, content:self.work))
        }
        if self.education.characters.count > 0 {
            info.append((infoType:.Education, content:self.education))
        }
        if self.children.characters.count > 0 {
            info.append((infoType:.Children, content:self.children))
        }
        
        return info
    }
    func ternaryInfo() -> [ProfileInfo] {
        var info:[ProfileInfo] = []
        
        if self.ethnicity.characters.count > 0 {
            info.append((infoType:.Ethnicity, content:self.ethnicity))
        }
        if self.music.characters.count > 0 {
            info.append((infoType:.Music, content:self.music))
        }
        if self.about.characters.count > 0 {
            info.append((infoType:.About, content:self.about))
        }
        
        return info
    }
    
    func getMutualFriendsCount(callback:(count:Int) -> Void) {
        if self.objectId == BLUser.currentUser()?.objectId { return }
        
        getMutualFriendsList { (people) -> Void in
            if people != nil {
                callback(count: people!.count)
            }
            else {
                callback(count: 0)
            }
        }
    }
    
    func getMutualFriendsList(callback:(people:[[NSObject:AnyObject]]?) -> Void) {
        if self.objectId == BLUser.currentUser()?.objectId { return }
        
        let params = ["fields":"context.fields(mutual_friends)"]
        let facebookRequest = FBSDKGraphRequest(graphPath: "/\(self.facebookId)", parameters: params)
        facebookRequest.startWithCompletionHandler { (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if error == nil {
                let context = result.objectForKey("context") as? [String:AnyObject]
                let mutualFriends = context?["mutual_friends"] as? [NSObject:AnyObject]
                let data = mutualFriends?["data"] as? [[NSObject:AnyObject]]
                callback(people: data)
            }
            else {
                callback(people: nil)
            }
        }
    }
    
    
    class func setupNewUser(user:PFUser, done:(success:Bool) -> Void) {
        if user.isNew {
            let params = ["fields":"id, email, first_name, gender, last_name, name, birthday", "locale":"en"]
            let fbRequest = FBSDKGraphRequest(graphPath: "me", parameters: params)
            fbRequest.startWithCompletionHandler({ (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
                if error == nil {
                    user.email = result.objectForKey("email") as? String
                    user["facebookId"] = result.objectForKey("id")
                    user["firstName"] = result.objectForKey("first_name")
                    user["lastName"] = result.objectForKey("last_name")
                    user["name"] = result.objectForKey("name")
                    user["profileComplete"] = false
                    user["notifyNewMatch"] = true
                    user["notifyNewAnswer"] = true
                    user["notifyNewMessage"] = true
                    user["notifyNewQuestion"] = true
                    user["lang"] = BlurvClient.languageShortCode()
                    
                    if let gender = result.objectForKey("gender") as? String {
                        let isMale = gender == "male" ? true:false
                        user["isMale"] = isMale
                        user["discoverGender"] = isMale ? 1:0
                    }
                    
                    BlurvClient.sharedClient.dateFormatter.dateFormat = "MM/dd/yyyy"
                    if let birthdayString = result.objectForKey("birthday") as? String {
                        if let birthdate = BlurvClient.sharedClient.dateFormatter.dateFromString(birthdayString) {
                            user["birthdate"] = birthdate
                        }
                    }
                    
                    user.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) -> Void in
                        if success {
                            done(success: true)
                        }
                        else {
                            done(success: false)
                        }
                    })
                }
                else {
                    done(success: false)
                }
            })
        }
    }
    
    
}











