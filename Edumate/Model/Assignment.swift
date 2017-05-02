//
//  Assignment.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/15/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation

struct Assignment: Equatable, FirebaseType {
    
    fileprivate let kName = "name"
    fileprivate let kDescription = "description"
    fileprivate let KDueDate = "dueDate"
    fileprivate let kAdmin = "admin"
    fileprivate let kCourse = "course"
    
    var name: String
    var description: String?
    var dueDate: NSNumber
    var admin: String
    var course: String?
    var identifier: String?
    var endpoint: String {
        return "assignments"
    }
    
    var jsonValue: [String: AnyObject] {
        var json: [String: AnyObject] = [kName : name as AnyObject, KDueDate : dueDate, kAdmin: admin as AnyObject]
        
        if let description = description {
            json.updateValue(description as AnyObject, forKey: kDescription)
        }
        
        if let course = course {
            json.updateValue(course as AnyObject, forKey: kCourse)
        }
        
        return json
    }
    
    init?(json: [String : AnyObject], identifier: String) {
        guard let name = json[kName] as? String,
            let dueDate = json[kDescription] as? NSNumber,
            let admin = json[kAdmin] as? String else { return nil }
        
        self.name = name
        self.description = json[kDescription] as? String
        self.dueDate = dueDate
        self.admin = admin
        self.course = json[kCourse] as? String
        self.identifier = identifier
    }
    
    init(name: String, description: String?, dueDate: NSNumber, admin: String, course: String?, identifier: String?) {
        self.name = name
        self.description = description
        self.dueDate = dueDate
        self.admin = admin
        self.course = course
        self.identifier = identifier
    }
    
}

func ==(lhs: Assignment, rhs: Assignment) -> Bool {
    return (lhs.name == rhs.name) && (lhs.identifier == rhs.identifier)
}
