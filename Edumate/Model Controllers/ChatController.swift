//
//  ChatController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/25/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation
import UIKit

class ChatController {
    
    static func chatWithUser(_ user: User, completion: @escaping (_ chat: Chat?) -> Void) {
        var chatIdentifier = String()
        if UserController.shared.currentUser.identifier!<user.identifier! {
            chatIdentifier = "\(UserController.shared.currentUser.identifier!)_\(user.identifier!)"
        } else {
            chatIdentifier = "\(user.identifier!)_\(UserController.shared.currentUser.identifier!)"
        }
        self.chatWithIdentifier(chatIdentifier) { (chat) in
            if let chat = chat {
                self.addUserToChat(UserController.shared.currentUser, chat: chat, completion: { (success) in
                    if success {
                        completion(chat)
                    } else {
                        completion(nil)
                    }
                })
            } else {
                self.createChatWithUser(user, completion: { (newChat) in
                    if let newChat = newChat {
                        completion(newChat)
                    } else {
                        completion(nil)
                    }
                })
            }
        }
    }
    
    static func createChatWithUser(_ user: User, completion: @escaping (_ chat: Chat?) -> Void) {
        let lastMessage = "\(UserController.shared.currentUser.firstName()) added \(user.firstName()) to the conversation."
        var chatIdentifier = String()
        if UserController.shared.currentUser.identifier!<user.identifier! {
            chatIdentifier = "\(UserController.shared.currentUser.identifier!)_\(user.identifier!)"
        } else {
            chatIdentifier = "\(user.identifier!)_\(UserController.shared.currentUser.identifier!)"
        }
        let timestamp = NSNumber(integerLiteral: Int(Date().timeIntervalSince1970))
        var chat = Chat(lastMessage: lastMessage, timestamp: timestamp, typing: nil, unread: [user.identifier! : 1], identifier: chatIdentifier)
        addUserToChat(user, chat: chat) { (success) in
            if success {
                addUserToChat(UserController.shared.currentUser, chat: chat, completion: { (success) in
                    if success {
                        chat.save()
                        completion(chat)
                    } else {
                        completion(nil)
                    }
                })
            } else {
                completion(nil)
            }
        }
    }
    
    static func addUserToChat(_ user: User, chat: Chat, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/chats/\(chat.identifier!)/users/\(user.identifier!)").setValue(true)
        completion(true)
    }
    
    static func removeUserFromChat(_ user: User, chat: Chat, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/chats/\(chat.identifier!)/users/\(user.identifier!)").setValue(false)
        completion(true)
    }
    
    static func userForChat(_ chat: Chat, completion: @escaping (_ user: User?) -> Void ) {
        var uidArr = chat.identifier!.components(separatedBy: "_")
        let currentUserIndex = uidArr.index(of: UserController.shared.currentUser.identifier!)
        uidArr.remove(at: currentUserIndex!)
        UserController.userWithIdentifier(uidArr[0], completion: { (user) -> Void in
            if let user = user {
                completion(user)
            } else {
                completion(nil)
            }
        })
    }

    static func observeChatsForUser(_ user: User, completion: @escaping (_ chats: [Chat]?, _ users: [User?]?) -> Void) {
        print("Observing chats")
        FirebaseController.base.child("/chats").queryOrdered(byChild: "users/\(user.identifier!)").queryEqual(toValue: true).observe(.value, with: { snapshot in
            print("Firebase returned chats: \(snapshot)")
            if let chatDictionaries = snapshot.value as? [String: AnyObject] {
                let chats = orderChats(chatDictionaries.flatMap({Chat(json: $0.1 as! [String : AnyObject], identifier: $0.0)}))
                var users = [User?]()
                var chatCount = 0
                for chat in chats {
                    ChatController.userForChat(chat) { (user) in
                        if let user = user {
                            users.append(user)
                        } else {
                            users.append(nil)
                        }
                        chatCount += 1
                        print(chatCount)
                        print(chats.count)
                        if chatCount == chats.count {
                            print("Fetched users.")
                            completion(chats, users)
                        }
                    }
                }
            } else {
                completion(nil, nil)
            }
        })
    }

    static func stopObservingChats(_ chats: [Chat]) {
        for chat in chats {
            FirebaseController.base.child("/chats/\(chat.identifier!)").removeAllObservers()
        }
    }

    static func chatWithIdentifier(_ identifier: String, completion: @escaping (_ chat: Chat?) -> Void) {
        FirebaseController.dataAtEndpoint("/chats/\(identifier)") { (data) -> Void in
            if let data = data as? [String: AnyObject] {
                let chat = Chat(json: data, identifier: identifier)
                completion(chat)
            } else {
                completion(nil)
            }
        }
    }
    
    static func observeMessagesIn(_ chat: Chat, completion: @escaping (_ messages: [Message]?) -> Void) {
        FirebaseController.observeDataAtEndpoint("/messages/\(chat.identifier!)") { (json) in
            if let json = json as? [String: AnyObject] {
                var messages = [Message]()
                var messageCount = 0
                for key in json.keys {
                    if let messageDict = json[key] {
                        let text = messageDict["text"] as! String
                        let sender = messageDict["sender"] as! String
                        let timestamp = messageDict["timestamp"] as! NSNumber
                        var readBool = Bool()
                        if let read = messageDict["read"] as? Bool {
                            readBool = read
                        } else {
                            readBool = false
                        }
                        let message = Message(text: text, sender: sender, timestamp: timestamp, read: readBool, identifier: key)
                        self.readMessageInChat(message, chat: chat, completion: { (readMessage) in
                            if let readMessage = readMessage {
                                messages.append(readMessage)
                            } else {
                                messages.append(message)
                            }
                            messageCount += 1
                            if messageCount == json.count {
                                if messages.count > 0 {
                                    completion(messages)
                                } else {
                                    completion(nil)
                                }
                            }
                        })
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    static func observeTypingIn(_ chat: Chat, completion: @escaping (_ users: [User]?) -> Void) {
        FirebaseController.observeDataAtEndpoint("/chats/\(chat.identifier!)/typing") { (data) in
            if let json = data as? [String: AnyObject] {
                var users = [User]()
                var userCount = 0
                for userDict in json {
                    UserController.userWithIdentifier(userDict.0, completion: { (user) -> Void in
                        if let user = user {
                            if user != UserController.shared.currentUser! {
                                users.append(user)
                            }
                            userCount += 1
                            if userCount == data?.count {
                                if users.count > 0 {
                                    completion(users)
                                } else {
                                    completion(nil)
                                }
                            }
                        } else {
                            userCount += 1
                            if userCount == data?.count {
                                if users.count > 0 {
                                    completion(users)
                                } else {
                                    completion(nil)
                                }
                            }
                        }
                    })
                }
            } else {
                completion(nil)
            }
        }
    }
    
    static func stopObservingChat(_ chat: Chat) {
        FirebaseController.base.child("/chats/\(chat.identifier!)").removeAllObservers()
        FirebaseController.base.child("/messages/\(chat.identifier!)").removeAllObservers()
        FirebaseController.base.child("/chats/\(chat.identifier!)/typing").removeAllObservers()
    }
    
    static func userIsTypingInChat(_ typing: Bool, chat: Chat) {
        let endpoint = "chats/\(chat.identifier!)/typing/\(UserController.shared.currentUser.identifier!)"
        let userIsTypingRef = FirebaseController.base.child(endpoint)
        if typing {
            userIsTypingRef.setValue(true)
        } else {
            userIsTypingRef.removeValue()
        }
        userIsTypingRef.onDisconnectRemoveValue()
    }
    
    static func sendMessageToUser(_ text: String, chat: Chat, user: User, completion: @escaping (_ message: Message?) -> Void) {
        let timestamp = NSNumber(integerLiteral: Int(NSDate().timeIntervalSince1970))
        if let currentUser = UserController.shared.currentUser {
            UserController.pushToken(for: user, completion: { (token) in
                if let token = token {
                    print("Sending notification to \(currentUser.firstName())")
                    OneSignalController.notify(user: user, text: text, player_id: token)
                }
            })
            let message = Message(text: text, sender: currentUser.identifier!, timestamp: timestamp, read: false, identifier: nil)
            FirebaseController.base.child("/messages/\(chat.identifier!)").childByAutoId().setValue(message.jsonValue) { (error, ref) in
                if error == nil {
                    let lastMessage = text
                    if let unreadCount = chat.unread?[user.identifier!] as? Int {
                        var chat = Chat(lastMessage: lastMessage, timestamp: timestamp, typing: nil, unread: [user.identifier! : unreadCount + 1], identifier: chat.identifier!)
                        chat.save()
                    } else {
                        var chat = Chat(lastMessage: lastMessage, timestamp: timestamp, typing: nil, unread: [user.identifier! : 1], identifier: chat.identifier!)
                        chat.save()
                    }
                    completion(message)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    static func sendMessageToCourse(_ text: String, chat: Chat, course: Course, completion: @escaping (_ message: Message?) -> Void) {
        let timestamp = NSNumber(integerLiteral: Int(NSDate().timeIntervalSince1970))
        if let currentUser = UserController.shared.currentUser {
            let message = Message(text: text, sender: currentUser.identifier!, timestamp: timestamp, read: false, identifier: nil)
            FirebaseController.base.child("/messages/\(chat.identifier!)").childByAutoId().setValue(message.jsonValue) { (error, ref) in
                if error == nil {
                    let lastMessage = "\(currentUser.firstName()): \(message.text)"
                    var chat = Chat(lastMessage: lastMessage, timestamp: timestamp, typing: chat.typing, unread: chat.unread, identifier: chat.identifier!)
                    chat.save()
                    self.updateCourseChat(course, chat: chat)
                    completion(message)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    static func updateCourseChat(_ course: Course, chat: Chat) {
        CourseController.usersForCourse(course) { (users) in
            if let users = users {
                for user in users {
                    if let currentUser = UserController.shared.currentUser, user != currentUser {
                        if let unreadCount = chat.unread?[user.identifier!] as? Int {
                            FirebaseController.base.child("/chats/\(chat.identifier!)/unread").updateChildValues([user.identifier! : unreadCount + 1])
                        } else {
                            FirebaseController.base.child("/chats/\(chat.identifier!)/unread").updateChildValues([user.identifier! : 1])
                        }
                    }
                }
            }
        }
    }
    
    static func readMessageInChat(_ message: Message, chat: Chat, completion: @escaping (_ message: Message?) -> Void) {
        if let currentUser = UserController.shared.currentUser, message.sender != currentUser.identifier! {
            FirebaseController.base.child("/messages/\(chat.identifier!)/\(message.identifier!)").updateChildValues(["read" : true], withCompletionBlock: { (error, ref) in
                if error == nil {
                    var readMessage = message
                    readMessage.read = true
                    completion(readMessage)
                } else {
                    completion(nil)
                }
            })
        } else {
            completion(nil)
        }
    }
    
    static func orderChats(_ chats: [Chat]) -> [Chat] {
        return chats.sorted(by: {TimeInterval($0.0.timestamp) > TimeInterval($0.1.timestamp)})
    }
    
}

