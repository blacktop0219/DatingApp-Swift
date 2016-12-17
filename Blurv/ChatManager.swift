//
//  ChatManager.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-04-19.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import Firebase


protocol ChatObserver {
    func chatDidReceiveNewMessage(message:ChatMessage, atIndex index:Int)
    //func didRemoveMessage(index:Int)
}

protocol ChatManagerObserver {
    func chatManagerDidAddNewChat(chat:Chat, atIndex index:Int)
    func chatManagerChatDidChange(newChat:Chat, atIndex index:Int)
    func chatManagerChatDidMove(newChat:Chat, fromIndex:Int, toIndex:Int)
    func chatManagerDidRemoveChat(atIndex index:Int)
}

class ChatManager: NSObject {
    
    static let sharedManager = ChatManager()
    
    struct ChatConfig {
        static let span:Int = 1000
    }
    
    let chatsRef = Firebase(url: "https://blurv.firebaseio.com/chats")
    let usersRef = Firebase(url: "https://blurv.firebaseio.com/users")
    
    private var chatListObservers = [ChatManagerObserver]()
    private var chatObservers = [String:[ChatObserver]]()
    
    private(set) var currentUserId:String?
    
    private var chatMessagesHandles = [String:UInt]()
    private var chatInfoHandles = [String:UInt]()
    private var chatListAddHandle:UInt?
    private var chatListRemoveHandle:UInt?
    
    var chats = [Chat]()
    var messages = [String:[ChatMessage]]()
    
    // Init/Setup/Launch
    
    func setUserId(userId:String) {
        stopObservingUserChats()
        self.currentUserId = userId
        observeUserChats()
    }
    private func setupNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserverForName("NOTIFICATION_LOGOUT", object: nil, queue:nil) { (notif:NSNotification) in
            self.stopObservingUserChats()
        }
    }
    
    
    // MARK: Firebase references
    
    private func refChatInfo(chatId:String) -> Firebase {
        return chatsRef.childByAppendingPath(chatId).childByAppendingPath("info")
    }
    private func refChatsForUser(userId:String) -> Firebase {
        return usersRef.childByAppendingPath(userId).childByAppendingPath("chats")
    }
    private func refMessagesForChatId(chatId:String) -> Firebase {
        return chatsRef.childByAppendingPath(chatId).childByAppendingPath("messages")
    }
    
    
    // MARK: Actions
    func createChat(otherUsers:[String], sourceGame gameId:String, callback:(chat:Chat?) -> Void) {
        if let userId = self.currentUserId {
            GameManager.sharedManager.getGameForGameId(gameId, callback: { (game) in
                if game != nil {
                    if let existingChatId = game!.chatId {
                        ChatManager.sharedManager.getChatWithId(existingChatId, callback: { (chat) in
                            callback(chat: chat)
                        })
                    }
                    else {
                        let theChatRef = self.chatsRef.childByAutoId()
                        let chatId = theChatRef.key
                        
                        var theUsers = otherUsers
                        if !theUsers.contains(userId) {
                            theUsers.append(userId)
                        }
                        let chat = Chat(userIds: theUsers, chatId: chatId, sourceGameId: gameId)
                        
                        let infoRef = self.refChatInfo(chatId)
                        infoRef.setValue(chat.info.toDictionnary())
                        
                        let messagesRef = self.refMessagesForChatId(chatId)
                        messagesRef.setValue(["+":true])
                        
                        for aUserId in theUsers {
                            let ref = self.refChatsForUser(aUserId).childByAppendingPath(chatId)
                            ref.setValue(true)
                        }
                        
                        callback(chat: chat)
                    }
                }
                else {
                    callback(chat: nil)
                }
            })
        }
    }
    
    func sendMessage(chat:Chat, content:String) {
        if let userId = self.currentUserId {
            BlurvClient.getTime({ (time) in
                if time != nil {
                    let ref = self.refMessagesForChatId(chat.id).childByAutoId()
                    let messageId = ref.key
                    
                    let message = ChatMessage(body: content, userId: userId, messageId: messageId, timestamp: time!.timeIntervalSince1970)
                    let messageDict = message.toDictionnary()
                    
                    ref.setValue(messageDict)
                    
                    chat.info.lastMessage = message
                    chat.info.lastActivity = message.timestamp
                    
                    for aUserId in chat.info.otherUsersIds() {
                        chat.info.users[aUserId]?.unread = true
                    }
                    
                    self.refChatInfo(chat.id).setValue(chat.info.toDictionnary())
                    
                    
                    // Send notif
                    self.refChatInfo(chat.id).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot:FDataSnapshot!) in
                        if let info = ChatInfo(dictionnary: snapshot.value) {
                            for aUserId in info.otherUsersIds() {
                                if !info.userIsOut(aUserId) {
                                    NotificationManager.sharedManager.sendNotificationForNewMessage(chat.id, messageBody: content, receiverUserId: aUserId)
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    
    func markAsRead(chatId:String) {
        if let user = BLUser.currentUser() {
            let ref = refChatInfo(chatId).childByAppendingPath("users").childByAppendingPath(user.objectId!).childByAppendingPath("unread")
            ref.setValue(false)
        }
    }

    func getChatWithId(chatId:String, callback:(chat:Chat?) -> Void) {
        refChatInfo(chatId).observeSingleEventOfType(.Value) { (snapshot:FDataSnapshot!) in
            if let chat = Chat(info: snapshot.value, chatId: chatId) {
                chat.loadUsers({ (success) in
                    if success {
                        self.updateChat(chat, id: chatId)
                        callback(chat: chat)
                    }
                    else {
                        callback(chat: nil)
                    }
                })
            }
            else {
                callback(chat: nil)
            }
        }
    }
    
    
    // MARK: Observe
    
    private func observeUserChats() {
        if let userId = self.currentUserId {
            chatListAddHandle = refChatsForUser(userId).observeEventType(.ChildAdded) { (snapshot:FDataSnapshot!) in
                let chatId = snapshot.key
                
                self.refChatInfo(chatId).observeSingleEventOfType(.Value, withBlock: { (snapshot:FDataSnapshot!) in
                    if let chat = Chat(info: snapshot.value, chatId: chatId) {
                        self.addChat(chat)
                    }
                    else {
                        print("chat object could not be created (1)")
                    }
                })
            }
            
            chatListRemoveHandle = refChatsForUser(userId).observeEventType(FEventType.ChildRemoved) { (snapshot:FDataSnapshot!) in
                let chatId = snapshot.key
                self.removeChat(chatId)
            }
        }
    }
    private func observeChat(chatId:String) {
        self.chatInfoHandles[chatId]
            = self.refChatInfo(chatId).observeEventType(FEventType.Value, withBlock: { (snapshot:FDataSnapshot!) in
                if let chat = Chat(info: snapshot.value, chatId: chatId) {
                    self.updateChat(chat, id: chatId)
                }
                else {
                    print("chat object could not be created (2)")
                }
            })
        
        
        self.chatMessagesHandles[chatId] = self.refMessagesForChatId(chatId).observeEventType(.ChildAdded, withBlock: { (snapshot:FDataSnapshot!) in
            let messageId = snapshot.key
            if let message = ChatMessage(dictionnary: snapshot.value, id: messageId) {
                self.addMessage(message, chatId: chatId)
            }
        })
    }
    
    
    // MARK: Stop Observing
    
    private func stopObservingUserChats() {
        if let userId = currentUserId {
            if let addHandle = self.chatListAddHandle {
                refChatsForUser(userId).removeObserverWithHandle(addHandle)
            }
            if let removeHandle = self.chatListRemoveHandle {
                refChatsForUser(userId).removeObserverWithHandle(removeHandle)
            }
        }
        for (chatId, _) in chatInfoHandles {
            stopObservingChat(chatId)
        }
        for (chatId, _) in chatMessagesHandles {
            stopObservingChat(chatId)
        }
    }
    
    private func stopObservingChat(chatId:String) {
        if let infoHandle = chatInfoHandles[chatId] {
            self.refChatInfo(chatId).removeObserverWithHandle(infoHandle)
        }
        if let messagesHandle = chatMessagesHandles[chatId] {
            self.refMessagesForChatId(chatId).removeObserverWithHandle(messagesHandle)
        }
    }
    
    
    // MARK: Handle Events
    
    private func addMessage(message:ChatMessage, chatId:String) {
        if messages[chatId] == nil || messages[chatId]?.count == 0 {
            messages[chatId] = [message]
            notifyObservers(messageAdded: message, atIndex: 0, inChat: chatId)
        }
        else {
            for i in 0..<messages[chatId]!.count {
                let mirrorIndex = (messages[chatId]!.count - 1) - i
                if messages[chatId]![mirrorIndex].timestamp < message.timestamp {
                    let insertIndex = mirrorIndex + 1
                    messages[chatId]!.insert(message, atIndex: insertIndex)
                    notifyObservers(messageAdded: message, atIndex: insertIndex, inChat: chatId)
                    break
                }
                else if mirrorIndex == 0 {
                    messages[chatId]!.insert(message, atIndex: 0)
                    notifyObservers(messageAdded: message, atIndex: 0, inChat: chatId)
                }
            }
        }
    }
    
    private func addChat(chat:Chat) {
        chat.loadUsers { (success) in
            if success {
                if self.chats.count == 0 {
                    self.chats = [chat]
                    self.notifyObservers(chatAdded: chat, atIndex: 0)
                }
                else {
                    for i in 0..<self.chats.count {
                        let mirrorIndex = (self.chats.count - 1) - i
                        if self.chats[mirrorIndex].lastActivity() < chat.lastActivity() {
                            let insertIndex = mirrorIndex
                            self.chats.insert(chat, atIndex: mirrorIndex)
                            self.notifyObservers(chatAdded: chat, atIndex: insertIndex)
                            break
                        }
                        else if mirrorIndex == 0 {
                            self.chats.insert(chat, atIndex: 0)
                            self.notifyObservers(chatAdded: chat, atIndex: 0)
                        }
                    }
                }
                
                let chatId = chat.id
                
                self.observeChat(chatId)
            }
        }
    }
    
    private func updateChat(newChat:Chat, id:String) {
        newChat.loadUsers { (success) in
            if success {
                for (index, oldChat) in self.chats.enumerate() {
                    if oldChat.id == id {
                        let oldIndex = index
                        var newIndex = oldIndex
                        
                        self.chats.removeAtIndex(index)
                        
                        for i in 0...self.chats.count {
                            if i == self.chats.count {
                                newIndex = self.chats.count
                                break
                            }
                            else if self.chats[i].lastActivity() < newChat.lastActivity() {
                                newIndex = i
                                break
                            }
                        }
                        
                        if newIndex != oldIndex {
                            self.chats.insert(newChat, atIndex: newIndex)
                            self.notifyObservers(chatMoved: newChat, fromIndex: oldIndex, toIndex: newIndex)
                        }
                        else {
                            self.chats.insert(newChat, atIndex: newIndex)
                            self.notifyObservers(chatChanged: newChat, atIndex: newIndex)
                        }
                    }
                }
            }
        }
    }
    
    private func removeChat(chatId:String) {
        for (index, chat) in self.chats.enumerate() {
            if chat.id == chatId {
                self.chats.removeAtIndex(index)
                notifyObservers(chatRemoved: index)
                stopObservingChat(chatId)
                NSNotificationCenter.defaultCenter().postNotificationName("CHAT_REMOVED_" + chatId, object: nil)
            }
        }
    }
    
    
    
    // MARK: Observer Notifications
    private func notifyObservers(chatAdded chat:Chat, atIndex index:Int) {
        for anObserver in self.chatListObservers {
            anObserver.chatManagerDidAddNewChat(chat, atIndex: index)
        }
    }
    private func notifyObservers(chatChanged updatedChat:Chat, atIndex index:Int) {
        for anObserver in self.chatListObservers {
            anObserver.chatManagerChatDidChange(updatedChat, atIndex: index)
        }
    }
    private func notifyObservers(chatMoved updatedChat:Chat, fromIndex:Int, toIndex:Int) {
        for anObserver in self.chatListObservers {
            anObserver.chatManagerChatDidMove(updatedChat, fromIndex: fromIndex, toIndex: toIndex)
        }
    }
    private func notifyObservers(chatRemoved index:Int) {
        for anObserver in self.chatListObservers {
            anObserver.chatManagerDidRemoveChat(atIndex: index)
        }
    }
    private func notifyObservers(messageAdded message:ChatMessage, atIndex index:Int, inChat chatId:String) {
        if let observers = self.chatObservers[chatId] {
            for anObserver in observers {
                anObserver.chatDidReceiveNewMessage(message, atIndex: index)
            }
        }
    }
    


    // MARK: Add/Remove observers
    func addObserverForChatList(observer:ChatManagerObserver) -> [Chat]? {
        self.chatListObservers.append(observer)
        return self.chats
    }
    func addObserverForChatId(observer:ChatObserver, chatId:String) -> [ChatMessage]? {
        if self.chatObservers[chatId] == nil {
            self.chatObservers[chatId] = [observer]
        }
        else {
            self.chatObservers[chatId]!.append(observer)
        }
        
        if let theMessages = messages[chatId] {
            return theMessages
        }
        return nil
    }
    func removeObserverForChatId(observer:ChatObserver, chatId:String) {
        self.chatObservers[chatId] = nil
    }
    
    func messagesForChatId(chatId:String) -> [ChatMessage] {
        if let theMessages = messages[chatId] {
            return theMessages
        }
        return []
    }
    
    

    
}




























