//
//  Member.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/15/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation

struct Message {
    
    fileprivate let kText = "text"
    fileprivate let kSender = "sender"
    fileprivate let kTimestamp = "timestamp"
    fileprivate let kRead = "read"
    
    let text: String
    let sender: String
    let timestamp: NSNumber
    var read: Bool
    let identifier: String?
    
    var jsonValue: [String: AnyObject] {
        return [kText : text as AnyObject, kSender : sender as AnyObject, kTimestamp : timestamp, kRead : read as AnyObject]
    }
    
    init?(json: [String : AnyObject], identifier: String) {
        guard let text = json[kText] as? String,
            let sender = json[kSender] as? String,
            let timestamp = json[kTimestamp] as? NSNumber,
            let read = json[kRead] as? Bool else { return nil }
        
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.read = read
        self.identifier = identifier
    }
    
    init(text: String, sender: String, timestamp: NSNumber, read: Bool, identifier: String?) {
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.read = read
        self.identifier = identifier
    }
    
}
