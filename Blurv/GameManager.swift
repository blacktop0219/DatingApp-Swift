//
//  GameManager.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-14.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Firebase

enum QuestionStatus {
    case Locked, Incomplete, Complete, Invalid
}



protocol GameObserver {
    func gameDidChange(id:String, newGame:Game)
}

protocol GameManagerObserver {
    func newMatchAdded(newMatch game:Game, atIndex index:Int)
    func newMatchRemoved(atIndex index:Int)
    
    func gameAdded(newGame:Game, atIndex index:Int)
    func gameDidChange(newGame:Game, atIndex index:Int)
    func gameDidMove(newGame:Game, fromIndex oldIndex:Int, toIndex newIndex:Int)
    func gameRemoved(atIndex index:Int)
}


class GameManager: NSObject {

    static let sharedManager = GameManager()
    
    let gamesRef = Firebase(url: "https://blurv.firebaseio.com/games")
    let usersRef = Firebase(url: "https://blurv.firebaseio.com/users")
    
    var gameHandles = [String:UInt]()
    var matchHandles = [String:UInt]()
    var gameListAddHandle:UInt?
    var gameListRemoveHandle:UInt?
    
    var games:[Game] = []
    var newMatches:[Game] = []
    
    private var newMatchPopupQueue:[Game] = []
    
    var singleGameObservers:[String:GameObserver] = [:]
    var managerObservers:[GameManagerObserver] = []
    
    
    
    // MARK: Init/Setup/Launch

    override init() {
        super.init()
        setupNotificationObservers()
    }
    private func setupNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserverForName("NOTIFICATION_LOGOUT", object: nil, queue:nil) { (notif:NSNotification) in
            self.stopObservingGameList()
        }
    }
    func start() {
        observeCurrentUserGames()
    }
    
    
    
    // MARK: Get Firebase References
    
    private func refGameForGameId(gameId:String) -> Firebase {
        return gamesRef.childByAppendingPath(gameId)
    }
    private func refUserInGame(gameId:String, userId:String) -> Firebase {
        return gamesRef.childByAppendingPath("\(gameId)/users/\(userId)")
    }
    private func refAnswerInGame(gameId:String, questionIndex index:Int, userId:String) -> Firebase {
        return gamesRef.childByAppendingPath("\(gameId)/questions/\(String(index))/answers/\(userId)")
    }
    private func refGamesForUser(userId:String) -> Firebase {
        return usersRef.childByAppendingPath("\(userId)/games")
    }
    
    
    
    // MARK: Actions
    
//    func getLocalGameForGameId(gameId:String) -> Game? {
//        for aGame in self.newMatches {
//            if gameId == aGame.id {
//                return aGame
//            }
//        }
//        for aGame in self.games {
//            if gameId == aGame.id {
//                return aGame
//            }
//        }
//        return nil
//    }
    
    func getGameForGameId(gameId:String, callback:(game:Game?) -> Void) {
        refGameForGameId(gameId).observeSingleEventOfType(FEventType.Value) { (snapshot:FDataSnapshot!) in
            if let game = Game(dictionnary: snapshot.value, gameId: gameId) {
                game.loadOtherUser({ (success) in
                    if success {
                        self.updateGame(gameId, newGame: game)
                        callback(game: game)
                    }
                    else {
                        callback(game: nil)
                    }
                })
            }
            else {
                callback(game: nil)
            }
        }
    }
    
    func createGame(userIds:[String]) {
        // Create game
        let theGameRef = gamesRef.childByAutoId()
        let theGame = Game(userIds: userIds, id: theGameRef.key)
        let gameId = theGameRef.key
        let gameDict = theGame.toDictionnary()
        theGameRef.setValue(gameDict)
        
        // Add game to users games
        for anId in userIds {
            let userGameRef = refGamesForUser(anId).childByAppendingPath(theGameRef.key)
            userGameRef.setValue(true)
        }
        
        if let otherUserId = theGame.otherUserId() {
            NotificationManager.sharedManager.sendNotificationForNewMatch(otherUserId, gameId: gameId)
        }
        
        theGame.loadOtherUser { (success) in
            if success {
                AppDelegate.showMatch(theGame)
            }
        }
    }

    
    func setPoppedUpForGame(game:Game) {
        if let user = BLUser.currentUser() {
            let ref = refUserInGame(game.id!, userId: user.objectId!).childByAppendingPath("poppedUp")
            ref.setValue(true)
        }
    }
    
    func setNotNewMatchForGame(game:Game) {
        if let user = BLUser.currentUser() {
            if let index = newMatches.indexOf(game) {
                self.addGame(newMatches.removeAtIndex(index))
                notifyObservers(newMatchRemoved: game, atIndex: index)
            }
            let ref = refUserInGame(game.id!, userId: user.objectId!).childByAppendingPath("newMatch")
            ref.setValue(false)
        }
    }
    
    func markUnreadForOtherUser(game:Game) {
        if let user = game.otherUser {
            let ref = refUserInGame(game.id!, userId: user.objectId!).childByAppendingPath("unread")
            ref.setValue(true)
        }
    }
    
    func markAsRead(gameId:String) {
        if let user = BLUser.currentUser() {
            let ref = refUserInGame(gameId, userId: user.objectId!).childByAppendingPath("unread")
            ref.setValue(false)
        }
    }
    
    func setChatIdForGame(chatId:String, game:Game) -> Game {
        let ref = refGameForGameId(game.id!).childByAppendingPath("chatId")
        ref.setValue(chatId)
        game.chatId = chatId
        return game
    }
    
    func setLastActivity(game:Game) {
        let timestamp = NSNumber(double: NSDate().timeIntervalSince1970)
        let ref = refGameForGameId(game.id).childByAppendingPath("lastActivity")
        ref.setValue(timestamp)
    }
    
    func answer(questionIndex index:Int, inGame game:Game, content:String, callback:(success:Bool) -> Void) {
        if let currentUser = BLUser.currentUser() {
            setLastActivity(game)
            if let answer = game.questionAtIndex(index).setAnswerForCurrentUser(content) {
                let answerRef = refAnswerInGame(game.id!, questionIndex: index, userId: currentUser.objectId!)
                answerRef.setValue(answer.toDictionnary(), withCompletionBlock: { (error:NSError!, ref:Firebase!) in
                    
                    if error == nil {
                        self.markUnreadForOtherUser(game)
                        NotificationManager.sharedManager.cancelRemindersForGame(game)
                        if game.isNewMatch() {
                            self.setNotNewMatchForGame(game)
                        }
                        if game.questionAtIndex(index).answers.count == 2 {
                            AppDelegate.showNewPicture(game, pictureIndex: index)
                        }
                        
                        if let otherUserId = game.otherUserId() {
                            if !game.otherUserIsOut() {
                                NotificationManager.sharedManager.sendNotificationForNewAnswer(game.id, questionIndex: index, isSecondAnswer: game.questionAtIndex(index).answers.count == 2, receiverUserId: otherUserId)
                            }
                        }
                    }
                    callback(success: error == nil)
                })
            }
        }
        else {
            callback(success: false)
        }
    }
    
    
    func setReadyForChat(game:Game) {
        if let user = BLUser.currentUser() {
            BlurvClient.sharedClient.setActiveNow(true)
            if game.complete() && game.chatId == nil {
                let ref = refUserInGame(game.id!, userId: user.objectId!).childByAppendingPath("readyForChat")
                ref.setValue(true)
                
                if game.chatId == nil && game.otherUserReadyForChat() {
                    ChatManager.sharedManager.createChat([game.otherUserId()!], sourceGame: game.id, callback: { (chat) in
                        if chat != nil {
                            GameManager.sharedManager.setChatIdForGame(chat!.id, game: game)
                            chat!.users = [game.otherUser!, BLUser.currentUser()!]
                            
                            if let otherId = game.otherUserId() {
                                if !game.otherUserIsOut() {
                                    NotificationManager.sharedManager.sendNotificationForChatUnlocked(game.id, chatId: game.chatId!, receiverUserId: otherId)
                                }
                            }
                        }
                    })
                }
                else if !game.otherUserReadyForChat() {
                    if let otherId = game.otherUserId() {
                        if !game.otherUserIsOut() {
                            NotificationManager.sharedManager.sendNotificationForChatReady(game.id, receiverUserId: otherId)
                        }
                    }
                }
                NotificationManager.sharedManager.cancelRemindersForGame(game)
            }
        }
    }

    func setReminderScheduledForQuestion(questionIndex index:Int, inGame game:Game) {
        if let userId = BLUser.currentUser()?.objectId {
            refGameForGameId(game.id).childByAppendingPath("questions/\(String(index))/users/\(userId)/reminderScheduled").setValue(true)
        }
    }
    
    
    
    
    // MARK: Observe
    
    @objc private func observeCurrentUserGames() {
        if let user = BLUser.currentUser() {
            let currentUserGamesRef = refGamesForUser(user.objectId!)
            gameListAddHandle = currentUserGamesRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot:FDataSnapshot!) in
                let gameId = snapshot.key
                
                self.refGameForGameId(gameId).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot:FDataSnapshot!) in
                    if let game = Game(dictionnary: snapshot.value, gameId: snapshot.key) {
                        if game.isNewMatch() {
                            self.addNewMatch(game)
                        }
                        else {
                            self.addGame(game)
                        }
                    }
                    else {
                        print("game object could not be created (1)")
                    }
                })
            })
            gameListRemoveHandle = currentUserGamesRef.observeEventType(FEventType.ChildRemoved, withBlock: { (snapshot:FDataSnapshot!) in
                let gameId = snapshot.key
                self.removeGame(gameId)
            })
        }
    }
    
    
    
    // MARK: Stop Observing
    
    private func stopObservingGame(gameId:String) {
        if let gameHandle = gameHandles[gameId] {
            refGameForGameId(gameId).removeObserverWithHandle(gameHandle)
            self.gameHandles[gameId] = nil
        }
        else if let newMatchHandle = matchHandles[gameId] {
            refGameForGameId(gameId).removeObserverWithHandle(newMatchHandle)
            self.matchHandles[gameId] = nil
        }
    }
    @objc private func stopObservingGameList() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { 
            for (gameId, handle) in self.gameHandles {
                self.refGameForGameId(gameId).removeObserverWithHandle(handle)
            }
        }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { 
            for (gameId, handle) in self.matchHandles {
                self.refGameForGameId(gameId).removeObserverWithHandle(handle)
            }
        }
    }
    
    
    
    // MARK: Handle Events
    
    private func addNewMatch(game:Game) {
        if let otherUserId = game.otherUserId() {
            BlurvClient.getUserWithId(otherUserId, callback: { (user) in
                if user != nil {
                    game.otherUser = user
                    if self.newMatches.count == 0 {
                        self.newMatches = [game]
                        self.notifyObservers(newMatchAdded: game, atIndex: 0)
                    }
                    else {
                        for aMatch in self.newMatches {
                            if aMatch.id == game.id {
                                self.updateGame(game.id, newGame: game)
                                return
                            }
                        }
                        var newGamesArray = self.newMatches
                        newGamesArray.append(game)
                        newGamesArray.sortInPlace({ (game1, game2) -> Bool in
                            return game1.lastActivity > game2.lastActivity
                        })
                        self.newMatches = newGamesArray
                        var theIndex = self.newMatches.count
                        for (index, aGame) in self.newMatches.enumerate() {
                            if aGame.id == game.id {
                                theIndex = index
                            }
                        }
                        self.notifyObservers(newMatchAdded: game, atIndex: theIndex)
//                        for i in 0..<self.newMatches.count {
//                            let inverseIndex = (self.newMatches.count - 1) - i
//                            if self.newMatches[inverseIndex].lastActivity < game.lastActivity {
//                                self.newMatches.insert(game, atIndex: inverseIndex)
//                                self.notifyObservers(newMatchAdded: game, atIndex: inverseIndex)
//                                break
//                            }
//                            else if inverseIndex == 0 {
//                                self.newMatches.insert(game, atIndex: inverseIndex)
//                                self.notifyObservers(newMatchAdded: game, atIndex: inverseIndex)
//                            }
//                        }
                    }
                    
                    
                    let gameId = game.id!
                    let exp = NSDate().dateByAddingTimeInterval(5)
                    self.matchHandles[gameId] = self.refGameForGameId(gameId).observeEventType(FEventType.Value, withBlock: { (snapshot:FDataSnapshot!) in
                        if exp.timeIntervalSince1970 < NSDate().timeIntervalSince1970 {
                            if let game = Game(dictionnary: snapshot.value, gameId: gameId) {
                                self.updateGame(gameId, newGame: game)
                            }
                            else {
                                print("game object could not be created (3)")
                            }
                        }
                        
                    })
                }
                else {
                    print("could not load user with id: \(otherUserId) (2)")
                }
            })
        }
    }
    
    private func addGame(game:Game) {
        if let otherUserId = game.otherUserId() {
            BlurvClient.getUserWithId(otherUserId, callback: { (user) in
                if user != nil {
                    game.otherUser = user!
                    if self.games.count == 0 {
                        self.games = [game]
                        self.notifyObservers(gameAdded: game, atIndex: 0)
                    }
                    else {
                        for aGame in self.games {
                            if aGame.id == game.id {
                                self.updateGame(game.id, newGame: game)
                                return
                            }
                        }
                        var newGamesArray = self.games
                        newGamesArray.append(game)
                        newGamesArray.sortInPlace({ (game1, game2) -> Bool in
                            return game1.lastActivity > game2.lastActivity
                        })
                        self.games = newGamesArray
                        var theIndex = self.games.count
                        for (index, aGame) in self.games.enumerate() {
                            if aGame.id == game.id {
                                theIndex = index
                            }
                        }
                        self.notifyObservers(gameAdded: game, atIndex: theIndex)
//                        for i in 0..<self.games.count {
//                            let mirrorIndex = (self.games.count - 1) - i
//                            if self.games[mirrorIndex].lastActivity < game.lastActivity {
//                                self.games.insert(game, atIndex: mirrorIndex)
//                                self.notifyObservers(gameAdded: game, atIndex: mirrorIndex)
//                                break
//                            }
//                            else if mirrorIndex == 0 {
//                                self.games.insert(game, atIndex: mirrorIndex)
//                                self.notifyObservers(gameAdded: game, atIndex: mirrorIndex)
//                            }
//                        }
                    }
                    
                    let gameId = game.id!
                    let exp = NSDate().dateByAddingTimeInterval(5)
                    self.gameHandles[gameId] = self.refGameForGameId(gameId).observeEventType(FEventType.Value, withBlock: { (snapshot:FDataSnapshot!) in
                        if exp.timeIntervalSince1970 < NSDate().timeIntervalSince1970 {
                            if let game = Game(dictionnary: snapshot.value, gameId: gameId) {
                                self.updateGame(gameId, newGame: game)
                            }
                            else {
                                print("game object could not be created (2)")
                            }
                        }
                    })
                }
                else {
                    print("could not load user with id: \(otherUserId) (1)")
                }
            })
        }
        else {
            print("game does not have an otherUserId (1)")
        }
    }
    private func removeGame(gameId:String) {
        var done = false
        
        let process = { (game:Game, index:Int, newMatch:Bool) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                if newMatch {
                    self.newMatches.removeAtIndex(index)
                    self.notifyObservers(newMatchRemoved: game, atIndex: index)
                }
                else {
                    self.games.removeAtIndex(index)
                    self.notifyObservers(gameRemoved: game, atIndex: index)
                }
                self.stopObservingGame(gameId)
                NSNotificationCenter.defaultCenter().postNotificationName("GAME_REMOVED_" + game.id, object: nil)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { 
            for (index, game) in self.newMatches.enumerate() {
                if done { break }
                if game.id == gameId {
                    done = true
                    process(game, index, true)
                    break
                }
            }
        }
        
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { 
            for (index, game) in self.games.enumerate() {
                if done { break }
                if game.id == gameId {
                    done = true
                    process(game, index, false)
                    break
                }
            }
        }
        
    }
    private func updateGame(gameId:String, newGame:Game) {
        if self.games.count == 0 && self.newMatches.count == 0 { return }
        if let otherUserId = newGame.otherUserId() {
            BlurvClient.getUserWithId(otherUserId, callback: { (user) in
                if user != nil {
                    newGame.otherUser = user
                    var done = false
                    
                    let process = { (index:Int, oldGame:Game, wasNewMatch:Bool) -> Void in
                        if done { return }
                        done = true
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            if wasNewMatch {
                                if newGame.isNewMatch() {
                                    self.newMatches[index] = newGame
                                }
                                else {
                                    self.newMatches.removeAtIndex(index)
                                    self.notifyObservers(newMatchRemoved: oldGame, atIndex: index)
                                    
                                    if self.games.count == 0 {
                                        self.games = [newGame]
                                        self.notifyObservers(gameAdded: newGame, atIndex: 0)
                                    }
                                    else {
                                        for i in 0...self.games.count {
                                            if i == self.games.count {
                                                self.games.insert(newGame, atIndex: i)
                                                self.notifyObservers(gameAdded: newGame, atIndex: i)
                                                break
                                            }
                                            else if self.games[i].lastActivity < newGame.lastActivity {
                                                self.games.insert(newGame, atIndex: i)
                                                self.notifyObservers(gameAdded: newGame, atIndex: i)
                                                break
                                            }
                                        }
                                    }
                                }
                                self.notifyObservers(gameChanged: newGame.id, game: newGame)
                            }
                            else {
                                let oldIndex = index
                                var newIndex = oldIndex
                                
                                self.games.removeAtIndex(oldIndex)
                                
                                for i in 0...self.games.count {
                                    if i == self.games.count {
                                        newIndex = self.games.count
                                    }
                                    else if self.games[i].lastActivity < newGame.lastActivity {
                                        newIndex = i
                                        break
                                    }
                                }
                                
                                self.games.insert(newGame, atIndex: newIndex)
                                
                                if newIndex != oldIndex {
                                    self.notifyObservers(gameMoved: newGame, fromIndex: oldIndex, toIndex: newIndex)
                                }
                                else {
                                    self.notifyObservers(gameChanged: newGame, atIndex: newIndex)
                                }
                                self.notifyObservers(gameChanged: newGame.id!, game: newGame)
                            }
                        })
                    }
                    
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), {
                        for (index, oldGame) in self.games.enumerate() {
                            if gameId == oldGame.id {
                                process(index, oldGame, false)
                                break
                            }
                        }
                    })
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { 
                        for (index, oldMatch) in self.newMatches.enumerate() {
                            if gameId == oldMatch.id {
                                process(index, oldMatch, true)
                                break
                            }
                        }
                    })
                    
                    
                }
                else {
                    print("could not load user with id: \(otherUserId) (2)")
                }
            })
        }
        else {
            print("game does not have an otherUserId (2)")
        }
    }
    
    
    // MARK: Observer Notifications
    private func notifyObservers(gameChanged gameId:String, game:Game) {
        if let observer = singleGameObservers[gameId] {
            observer.gameDidChange(gameId, newGame: game)
        }
    }
    private func notifyObservers(gameChanged newGame:Game, atIndex index:Int) {
        for anObserver in managerObservers {
            anObserver.gameDidChange(newGame, atIndex: index)
        }
    }
    private func notifyObservers(gameMoved newGame:Game, fromIndex oldIndex:Int, toIndex newIndex:Int) {
        for anObserver in managerObservers {
            anObserver.gameDidMove(newGame, fromIndex: oldIndex, toIndex: newIndex)
        }
    }
    private func notifyObservers(newMatchAdded game:Game, atIndex index:Int) {
        for anObserver in managerObservers {
            anObserver.newMatchAdded(newMatch: game, atIndex: index)
        }
    }
    private func notifyObservers(newMatchRemoved game:Game, atIndex index:Int) {
        for anObserver in managerObservers {
            anObserver.newMatchRemoved(atIndex: index)
        }
    }
    private func notifyObservers(gameAdded game:Game, atIndex index:Int) {
        for anObserver in managerObservers {
            anObserver.gameAdded(game, atIndex: index)
        }
    }
    private func notifyObservers(gameRemoved game:Game, atIndex index:Int) {
        for anObserver in managerObservers {
            anObserver.gameRemoved(atIndex: index)
        }
    }
    
    
    
    // MARK: Observers Add/Remove
    func addObserver(observer:GameObserver, forGameId gameId:String) {
        singleGameObservers[gameId] = observer
    }
    func addObserverForGameList(observer:GameManagerObserver) {
        managerObservers.append(observer)
        
    }
    func removeObserver(observer:GameObserver, forGameId gameId:String) {
        singleGameObservers[gameId] = nil
    }
    func removeAllObserversForGameList() {
        managerObservers = []
        if let userId = BLUser.currentUser()?.objectId {
            if let addHandle = gameListAddHandle {
                refGamesForUser(userId).removeObserverWithHandle(addHandle)
            }
            if let removeHandle = gameListRemoveHandle {
                refGamesForUser(userId).removeObserverWithHandle(removeHandle)
            }
        }
    }
    
}









