//
//  Chat.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/25/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation

struct Chat: Equatable, FirebaseType {
    
    fileprivate let kLastMessage = "lastMessage"
    fileprivate let kTimestamp = "timestamp"
    fileprivate let kTyping = "typing"
    fileprivate let kUnread = "unread"
    
    var lastMessage: String
    var timestamp: NSNumber
    var typing: NSDictionary?
    var unread: NSDictionary?
    var identifier: String?
    var endpoint: String {
        return "chats"
    }
    
    var jsonValue: [String: AnyObject] {
        let json: [String: AnyObject] = [kLastMessage : lastMessage as AnyObject, kTyping : typing as AnyObject, kUnread : unread as AnyObject,  kTimestamp : timestamp as AnyObject]
        
        return json
    }
    
    init?(json: [String : AnyObject], identifier: String) {
        guard let lastMessage = json[kLastMessage] as? String,
            let timestamp = json[kTimestamp] as? NSNumber else { return nil }
        
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.typing = json[kTyping] as? NSDictionary
        self.unread = json[kUnread] as? NSDictionary
        self.identifier = identifier
    }
    
    init(lastMessage: String, timestamp: NSNumber, typing: NSDictionary?, unread: NSDictionary?, identifier: String?) {
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.typing = typing
        self.unread = unread
        self.identifier = identifier
    }
    
}

func ==(lhs: Chat, rhs: Chat) -> Bool {
    return (lhs.identifier == rhs.identifier)
}
