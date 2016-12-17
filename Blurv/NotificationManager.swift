//
//  NotificationManager.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-26.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Parse
import LNNotificationsUI


enum NotificationType {
    case NewMatch, NewAnswer, NewPicture, LastPicture, ChatReady, ChatUnlocked, NewChatMessage
    
    func typeString() -> String {
        switch self {
        case .NewMatch:
            return "new_match"
        case .NewAnswer:
            return "new_answer"
        case .NewPicture:
            return "new_picture"
        case .LastPicture:
            return "last_picture"
        case .ChatReady:
            return "chat_ready"
        case .ChatUnlocked:
            return "chat_unlocked"
        case .NewChatMessage:
            return "new_chat_message"
        }
    }
}

class NotificationManager: NSObject {
    
    static let sharedManager = NotificationManager()
    
    private var currentNotifications:[BLNotification] = [] {
        didSet {
            updateBadgeCount()
            NSNotificationCenter.defaultCenter().postNotificationName("NOTIFICATION_GLOBAL_NOTIFICATION_COUNT_CHANGED", object: nil)
        }
    }
    
    static var notificationCount:Int {
        return NotificationManager.sharedManager.currentNotifications.count
    }
    
    var readTimestamps:[String:NSTimeInterval] = [:]
    
    override init() {
        super.init()
        
        LNNotificationCenter.defaultCenter().notificationsBannerStyle = .Light
        LNNotificationCenter.defaultCenter().registerApplicationWithIdentifier("blurv", name: "Blurv", icon: UIImage(named: "notif_banner_icon"), defaultSettings: LNNotificationAppSettings.defaultNotificationAppSettings())
    }
    
    
    
    func hasGameNotifications() -> Bool {
        for aNotif in currentNotifications {
            if aNotif.gameId != nil {
                return true
            }
        }
        return false
    }
    func hasChatNotifications() -> Bool {
        for aNotif in currentNotifications {
            if aNotif.chatId != nil {
                return true
            }
        }
        return false
    }
    
    func updateInstallation() {
        if let user = BLUser.currentUser() {
            PFInstallation.currentInstallation()["userId"] = user.objectId!
        }
        else {
            PFInstallation.currentInstallation().removeObjectForKey("userId")
        }
        PFInstallation.currentInstallation().saveInBackground()
    }
    
    func updateBadgeCount() {
        var convos = Set<String>()
        for aNotif in currentNotifications {
            if let id:String = aNotif.gameId ?? aNotif.chatId {
                if !convos.contains(id) {
                    convos.insert(id)
                }
            }
        }
        let count = convos.count
        UIApplication.sharedApplication().applicationIconBadgeNumber = count
        if PFInstallation.currentInstallation().badge != count {
            PFInstallation.currentInstallation().badge = count
            PFInstallation.currentInstallation().saveInBackground()
        }
    }
    
    func readNotificationsForGameWithId(gameId:String) {
        GameManager.sharedManager.markAsRead(gameId)
        self.readTimestamps[gameId] = NSDate().timeIntervalSince1970
        var toSave:[BLNotification] = []
        for notif in currentNotifications {
            if notif.gameId == gameId {
                notif.read = true
                toSave.append(notif)
                if let index = currentNotifications.indexOf(notif) {
                    currentNotifications.removeAtIndex(index)
                }
            }
        }
        if toSave.count > 0 {
            PFObject.saveAllInBackground(toSave)
        }
    }
    
    func readNotificationsForChatWithId(chatId:String) {
        ChatManager.sharedManager.markAsRead(chatId)
        self.readTimestamps[chatId] = NSDate().timeIntervalSince1970
        var toSave:[BLNotification] = []
        for notif in currentNotifications {
            if notif.chatId == chatId {
                notif.read = true
                toSave.append(notif)
                if let index = currentNotifications.indexOf(notif) {
                    currentNotifications.removeAtIndex(index)
                }
            }
        }
        if toSave.count > 0 {
            PFObject.saveAllInBackground(toSave)
        }
    }
    
    func readAllChatNotificationsBeforeUnmatch(chatId:String, callback:(success:Bool) -> Void) {
        if let query = BLNotification.query() {
            query.whereKey("meta", containsString: chatId)
            query.findObjectsInBackgroundWithBlock({ (results:[PFObject]?, error:NSError?) in
                if let notifs = results as? [BLNotification] {
                    for aNotif in notifs {
                        aNotif.read = true
                    }
                    PFObject.saveAllInBackground(notifs, block: { (success:Bool, error:NSError?) in
                        callback(success: success)
                    })
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
    
    func readAllGameNotificationsBeforeUnmatch(gameId:String, callback:(success:Bool) -> Void) {
        if let query = BLNotification.query() {
            query.whereKey("meta", containsString: gameId)
            query.findObjectsInBackgroundWithBlock({ (results:[PFObject]?, error:NSError?) in
                if let notifs = results as? [BLNotification] {
                    for aNotif in notifs {
                        aNotif.read = true
                    }
                    PFObject.saveAllInBackground(notifs, block: { (success:Bool, error:NSError?) in
                        callback(success: success)
                    })
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
    
    func notificationCountForGameWithId(gameId:String) -> Int {
        var count:Int = 0
        for notif in currentNotifications {
            if notif.gameId == gameId {
                count += 1
            }
        }
        return count
    }
    func notificationCountForChatWithId(chatId:String) -> Int {
        var count:Int = 0
        for notif in currentNotifications {
            if notif.chatId == chatId {
                count += 1
            }
        }
        return count
    }
    
    
    func sendNotificationForNewMessage(chatId:String, messageBody:String, receiverUserId:String) {
        let meta = [
            "chatId":chatId,
            "messageBody":messageBody
        ]
        sendNotification(NotificationType.NewChatMessage, toUser: receiverUserId, meta: meta)
    }
    func sendNotificationForNewAnswer(gameId:String, questionIndex: Int, isSecondAnswer:Bool, receiverUserId:String) {
        let meta:[String:AnyObject] = [
            "gameId":gameId,
            "questionIndex":questionIndex
        ]
        if isSecondAnswer {
            if questionIndex == 2 {
                sendNotification(NotificationType.LastPicture, toUser: receiverUserId, meta: meta)
            }
            else {
                sendNotification(NotificationType.NewPicture, toUser: receiverUserId, meta: meta)
            }
        }
        else {
            sendNotification(NotificationType.NewAnswer, toUser: receiverUserId, meta: meta)
        }
    }
    func sendNotificationForNewMatch(receiverUserId:String, gameId:String) {
        let meta:[String:AnyObject] = ["gameId":gameId]
        sendNotification(NotificationType.NewMatch, toUser: receiverUserId, meta: meta)
    }
    func sendNotificationForChatReady(gameId:String, receiverUserId:String) {
        let meta = [
            "gameId":gameId
        ]
        sendNotification(NotificationType.ChatReady, toUser: receiverUserId, meta: meta)
    }
    
    func sendNotificationForChatUnlocked(gameId:String, chatId:String, receiverUserId:String) {
        let meta = [
            "gameId":gameId,
        ]
        sendNotification(NotificationType.ChatUnlocked, toUser: receiverUserId, meta: meta)
    }
    
    
    
    private func sendNotification(type:NotificationType, toUser receiverId:String, meta:[String:AnyObject]) {
        let params:[NSObject:AnyObject] = [
            "type":type.typeString(),
            "to":receiverId,
            "meta":meta
        ]
        PFCloud.callFunctionInBackground("sendNotification", withParameters: params) { (result:AnyObject?, error:NSError?) in
            if error != nil {
                print("Error sending notification: \(error?.localizedDescription)")
            }
        }
    }
    
    /// *Synchronous* method
    private func fetchNotification(notificationId:String) -> BLNotification? {
        let notifBone = BLNotification(className: notificationId)
        do {
            let fetched = try notifBone.fetch()
            self.currentNotifications.append(fetched)
            return fetched
        }
        catch let error as NSError {
            print("Error fetching notification with id: \(notificationId)\n==> \(error.localizedDescription)")
            return nil
        }
    }
    
    
    /// *Synchronous* method
    func fetchAllUnread() {
        if let user = BLUser.currentUser() {
            let query = BLNotification.query()!
            query.whereKey("toId", equalTo: user.objectId!)
            query.whereKey("read", equalTo: false)
            do {
                let results = try query.findObjects()
                self.currentNotifications = results as! [BLNotification]
            }
            catch let error as NSError {
                print("Error fetching all notifications: \(error.localizedDescription)")
            }
        }
    }
    
    func showNotificationBanner(title:String? = nil, message:String, onTap:(() -> Void)) {
        
        let notification = LNNotification(message: message)
        if title != nil {
            notification.title = title
        }
        notification.defaultAction = LNNotificationAction(title: "Default Action", handler: { (action:LNNotificationAction!) in
            onTap()
        })
        LNNotificationCenter.defaultCenter().presentNotification(notification, forApplicationIdentifier: "blurv")
    }
    
    
    
    
    
    func handleForegroundNotification(userInfo:[NSObject:AnyObject]) {
        if let notificationId = userInfo["notificationId"] as? String {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), {
                if let notification = self.fetchNotification(notificationId) {
                    if let objectId = notification.gameId ?? notification.chatId {
                        let pushTimestamp = notification.createdAt?.timeIntervalSince1970 ?? NSDate().timeIntervalSince1970
                        if let readTimestamp = self.readTimestamps[objectId] {
                            if readTimestamp > pushTimestamp {
                                return
                            }
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        switch notification.type {
                        case "new_chat_message":
                            if let visible = AppDelegate.visibleViewController() as? ChatController {
                                if visible.chat.id == notification.metadata?["chatId"] as? String && visible.chat.id != nil {
                                    return
                                }
                            }
                            else if let visible = AppDelegate.visibleViewController() as? HomeController {
                                if visible.blurvSwitch.selectedMode == .Chats && visible.currentIndex == 2 {
                                    return
                                }
                            }
                            
                            if let body = notification.metadata?["messageBody"] as? String {
                                if let chatId = notification.chatId {
                                    ChatManager.sharedManager.getChatWithId(chatId, callback: { (chat) in
                                        if chat != nil {
                                            let from_name = notification.arguments?.first as? String ?? NSLocalizedString("New Message", comment: "")
                                            self.showNotificationBanner(from_name, message: body, onTap: {
                                                AppDelegate.routeToChat(chat!)
                                            })
                                        }
                                    })
                                }
                            }
                        case "new_match":
                            if let gameId = notification.gameId {
                                GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                                    if game != nil {
                                        let message = NSLocalizedString(notification.alertKey, comment: "")
                                        self.showNotificationBanner(message: message, onTap: { 
                                            AppDelegate.showMatch(game!)
                                        })
                                    }
                                })
                            }
                        case "new_answer":
                            if let gameId = notification.gameId,
                                from_name = notification.arguments?.first as? String,
                            questionIndex = notification.arguments?[1] as? Int {
                                if let visible = AppDelegate.visibleViewController() as? GameController {
                                    if visible.game.id == notification.gameId {
                                        return
                                    }
                                }
                                GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                                    if game != nil {
                                        let message = String(format: NSLocalizedString(notification.alertKey, comment: ""), from_name, String(questionIndex))
                                        self.showNotificationBanner(message: message, onTap: {
                                            AppDelegate.routeToGame(game!)
                                        })
                                    }
                                })
                            }
                        case "new_picture":
                            if let gameId = notification.gameId,
                                from_name = notification.arguments?.first as? String,
                            questionIndex = notification.metadata?.objectForKey("questionIndex") as? Int {
                                GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                                    if game != nil {
                                        if let visible = AppDelegate.visibleViewController() as? GameController {
                                            if visible.game.id == notification.gameId {
                                                AppDelegate.showNewPicture(game!, pictureIndex: questionIndex)
                                                return
                                            }
                                        }
                                        let message = String(format: NSLocalizedString(notification.alertKey, comment: ""), from_name)
                                        self.showNotificationBanner(message: message, onTap: {
                                            AppDelegate.showNewPicture(game!, pictureIndex: questionIndex)
                                        })
                                    }
                                })
                            }
                        case "last_picture":
                            if let gameId = notification.gameId,
                                from_name = notification.arguments?.first as? String {
                                GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                                    if game != nil {
                                        if let visible = AppDelegate.visibleViewController() as? GameController {
                                            if visible.game.id == notification.gameId {
                                                return
                                            }
                                        }
                                        let message = String(format: NSLocalizedString(notification.alertKey, comment: ""), from_name)
                                        self.showNotificationBanner(message: message, onTap: {
                                            AppDelegate.showChatUnlocked(game!)
                                        })
                                    }
                                })
                            }
                        case "chat_ready":
                            if let gameId = notification.gameId,
                                from_name = notification.arguments?.first as? String {
                                GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                                    if game != nil {
                                        if let visible = AppDelegate.visibleViewController() as? GameController {
                                            if visible.game.id == notification.gameId {
                                                return
                                            }
                                        }
                                        let message = String(format: NSLocalizedString(notification.alertKey, comment: ""), from_name)
                                        self.showNotificationBanner(message: message, onTap: {
                                            AppDelegate.showChatUnlocked(game!)
                                        })
                                    }
                                })
                            }
                        case "chat_unlocked":
                            if let gameId = notification.gameId,
                                from_name = notification.arguments?.first as? String {
                                GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                                    if let chatId = game?.chatId {
                                        ChatManager.sharedManager.getChatWithId(chatId, callback: { (chat) in
                                            if chat != nil {
                                                if let visible = AppDelegate.visibleViewController() as? GameController {
                                                    if visible.game.id == notification.gameId {
                                                        return
                                                    }
                                                }
                                                let message = String(format: NSLocalizedString(notification.alertKey, comment: ""), from_name)
                                                self.showNotificationBanner(message: message, onTap: {
                                                    AppDelegate.routeToChat(chat!)
                                                })
                                            }
                                        })
                                    }
                                })
                            }
                        default:
                            break
                        }
                    })
                }
            })
        }
    }
    
    func handleBackgroundNotification(userInfo:[NSObject:AnyObject]) {
        if let notificationId = userInfo["notificationId"] as? String {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), { 
                if let notification = self.fetchNotification(notificationId) {
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.performActionForNotification(notification)
                    })
                }
            })
        }
    }
    
    func performActionForNotification(notification:BLNotification) {
        switch notification.type {

        // ======= NEW CHAT MESSAGE ======
        case "new_chat_message":
            if let chatId = notification.chatId {
                ChatManager.sharedManager.getChatWithId(chatId, callback: { (chat) in
                    if chat != nil {
                        AppDelegate.routeToChat(chat!)
                    }
                })
            }
            
        // ======== NEW ANSWER ========
        case "new_answer", "new_picture", "last_picture":
            if let gameId = notification.gameId {
                GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                    if game != nil {
                        AppDelegate.routeToGame(game!)
                    }
                })
            }
        // ========= CHAT READY =========
        case "chat_ready":
            if let gameId = notification.gameId {
                GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                    if game != nil {
                        AppDelegate.routeToGame(game!)
                    }
                })
            }
        // ========= CHAT UNLOCKED =======
        case "chat_unlocked":
            if let chatId = notification.chatId {
                ChatManager.sharedManager.getChatWithId(chatId, callback: { (chat) in
                    if chat != nil {
                        AppDelegate.routeToChat(chat!)
                    }
                })
            }
            else if let gameId = notification.gameId {
                GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                    if game != nil {
                        AppDelegate.routeToGame(game!)
                    }
                })
            }
        default:
            break
        }
    }


    func scheduleReminderForQuestion(questionIndex:Int, inGame game:Game) {
        if !BLUser.currentUser()!.notifyNewQuestion { return }
        if game.questionAtIndex(questionIndex).reminderScheduled() { return }
        if let notifications = UIApplication.sharedApplication().scheduledLocalNotifications {
            for aNotif in notifications {
                if let type = aNotif.userInfo?["type"] as? String {
                    if type == "question_reminder" {
                        let gameId = aNotif.userInfo!["gameId"] as! String
                        let index = aNotif.userInfo!["questionIndex"] as! Int
                        if gameId == game.id && index == questionIndex {
                            return
                        }
                    }
                }
            }
        }
        GameManager.sharedManager.setReminderScheduledForQuestion(questionIndex: questionIndex, inGame: game)
        let otherUser = game.otherUser!
        let body = String(format: NSLocalizedString("question_reminder_alert_body", comment: ""), otherUser.firstName)
        let info:[NSObject:AnyObject] = ["type":"question_reminder", "gameId":game.id!, "questionIndex":questionIndex]
        let notification = UILocalNotification()
        notification.alertBody = body
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.fireDate = NSDate().dateByAddingTimeInterval(24*60*60)
        notification.userInfo = info
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        print("Scheduled reminder for game: \(game.id)")
    }

    func cancelRemindersForGame(game:Game) {
        if let notifications = UIApplication.sharedApplication().scheduledLocalNotifications {
            for aNotif in notifications {
                if let type = aNotif.userInfo?["type"] as? String {
                    if type == "question_reminder" {
                        let gameId = aNotif.userInfo!["gameId"] as! String
                        if gameId == game.id {
                            UIApplication.sharedApplication().cancelLocalNotification(aNotif)
                            print("Cancelled reminder for game: \(gameId)")
                        }
                    }
                }
            }
        }
    }

    func cancelAllLocalNotifications() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
}


