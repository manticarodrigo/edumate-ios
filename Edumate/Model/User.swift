//
//  User.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/12/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation

struct User: Equatable, FirebaseType {
    
    fileprivate let kName = "name"
    fileprivate let kUniversity = "university"
    
    var name: String
    var university: String?
    var identifier: String?
    var endpoint: String {
        return "users"
    }
    
    var jsonValue: [String: AnyObject] {
        var json: [String: AnyObject] = [kName: name as AnyObject]
        
        if let university = university {
            json.updateValue(university as AnyObject, forKey: kUniversity)
        }
        
        return json
    }
    
    init?(json: [String: AnyObject], identifier: String) {
        guard let name = json[kName] as? String else { return nil }
        
        self.name = name
        self.university = json[kUniversity] as? String
        self.identifier = identifier
    }
    
    init(name: String, university: String?, uid: String) {
        self.name = name
        self.university = university
        self.identifier = uid
    }
    
}

func ==(lhs: User, rhs: User) -> Bool {
    return (lhs.name == rhs.name) && (lhs.identifier == rhs.identifier)
}

extension User {
    
    func firstName() -> String {
        let fullNameArr = self.name.components(separatedBy: " ")
        let firstName = fullNameArr[0]
        
        return firstName
    }
    
}
