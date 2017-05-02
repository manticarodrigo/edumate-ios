//
//  Course.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/12/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation

struct Course: Equatable, FirebaseType {
    
    fileprivate let kName = "name"
    fileprivate let kDescription = "description"
    fileprivate let kUniversity = "university"
    fileprivate let kTerm = "term"
    fileprivate let kSubject = "subject"
    fileprivate let kAdmin = "admin"
    
    var name: String
    var description: String?
    var university: String
    var term: String
    var subject: Int
    var admin: String
    var identifier: String?
    var endpoint: String {
        return "courses"
    }
    
    var jsonValue: [String: AnyObject] {
        var json: [String: AnyObject] = [kName : name as AnyObject, kDescription : description as AnyObject, kUniversity : university as AnyObject, kTerm : term as AnyObject, kSubject : subject as AnyObject, kAdmin : admin as AnyObject]
        
        if let description = description {
            json.updateValue(description as AnyObject, forKey: kDescription)
        }
        
        return json
    }
    
    init?(json: [String : AnyObject], identifier: String) {
        guard let name = json[kName] as? String,
            let university = json[kUniversity] as? String,
            let term = json[kTerm] as? String,
            let subject = json[kSubject] as? Int,
            let admin = json[kAdmin] as? String else { return nil }
        
        self.name = name
        self.description = json[kDescription] as? String
        self.university = university
        self.term = term
        self.subject = subject
        self.admin = admin
        self.identifier = identifier
    }
    
    init(name: String, description: String?, university: String, term: String, subject: Int, admin: String, identifier: String?) {
        self.name = name
        self.description = description
        self.university = university
        self.term = term
        self.subject = subject
        self.admin = admin
        self.identifier = identifier
    }
    
}

func ==(lhs: Course, rhs: Course) -> Bool {
    return (lhs.name == rhs.name) && (lhs.identifier == rhs.identifier)
}
