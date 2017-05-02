//
//  UserController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/23/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation
import UIKit

class UserController {
    
    fileprivate let kUser = "userKey"
    
    var currentUser: User! {
        get {
            guard let uid = FirebaseController.auth?.currentUser?.uid,
                let userDictionary = UserDefaults.standard.value(forKey: kUser) as? [String: AnyObject] else {
                    return nil
            }
            return User(json: userDictionary, identifier: uid)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.setValue(newValue.jsonValue, forKey: kUser)
            } else {
                UserDefaults.standard.removeObject(forKey: kUser)
            }
        }
    }
    
    
    static let shared = UserController()
    
    static func userWithIdentifier(_ identifier: String, completion: @escaping (_ user: User?) -> Void) {
        FirebaseController.dataAtEndpoint("users/\(identifier)") { (data) -> Void in
            if let json = data as? [String: AnyObject] {
                let user = User(json: json, identifier: identifier)
                completion(user)
            } else {
                completion(nil)
            }
        }
    }
    
    static func observeAllUsers(_ completion: @escaping (_ users: [User]?) -> Void) {
        FirebaseController.observeDataAtEndpoint("/users") { (data) -> Void in
            if let json = data as? [String: AnyObject] {
                let users = json.flatMap({User(json: $0.1 as! [String : AnyObject], identifier: $0.0)})
                if let currentUser = UserController.shared.currentUser {
                    let usersWithoutCurrent = users.filter({$0 != currentUser})
                    completion(usersWithoutCurrent)
                } else {
                    completion(users)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    static func setPushToken(_ token: String?) {
        if let currentUser = shared.currentUser {
            FirebaseController.base.child("/users/\(currentUser.identifier!)/pushToken").setValue(token)
        }
    }
    
    static func pushToken(for user: User, completion: @escaping (_ token: String?) -> Void) {
        FirebaseController.dataAtEndpoint("/users/\(user.identifier!)/pushToken") { (token) -> Void in
            if let token = token as? String {
                completion(token)
            } else {
                completion(nil)
            }
        }
    }
    
    static func follow(_ user: User, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/users/\(shared.currentUser.identifier!)/follows/\(user.identifier!)").setValue(true)
        completion(true)
    }
    
    static func unfollow(_ user: User, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/users/\(shared.currentUser.identifier!)/follows/\(user.identifier!)").removeValue()
        completion(true)
    }
    
    static func userFollows(_ user: User, followsUser: User, completion: @escaping (_ follows: Bool) -> Void ) {
        FirebaseController.dataAtEndpoint("/users/\(user.identifier!)/follows/\(followsUser.identifier!)") { (data) -> Void in
            if let _ = data {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    static func followedBy(_ user: User, completion: @escaping (_ followed: [User]?) -> Void) {
        FirebaseController.dataAtEndpoint("/users/\(user.identifier!)/follows/") { (data) -> Void in
            if let json = data as? [String: AnyObject] {
                var users: [User] = []
                var objectCount = 0
                for userJson in json {
                    userWithIdentifier(userJson.0, completion: { (user) -> Void in
                        if let user = user {
                            users.append(user)
                            objectCount += 1
                            if objectCount == json.count {
                                completion(users)
                            }
                        } else {
                            objectCount += 1
                            if objectCount == json.count {
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
    
    static func tutor(_ subject: Int, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/users/\(shared.currentUser.identifier!)/tutors/\(subject)").setValue(true)
        completion(true)
    }
    
    static func untutor(_ subject: Int, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/users/\(shared.currentUser.identifier!)/tutors/\(subject)").removeValue()
        completion(true)
    }
    
    static func userTutors(_ user: User, subject: Int, completion: @escaping (_ tutors: Bool) -> Void ) {
        FirebaseController.dataAtEndpoint("/users/\(user.identifier!)/tutors/\(subject)") { (data) -> Void in
            if let _ = data {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    static func tutoredBy(_ user: User, completion: @escaping (_ subjects: [Int]?) -> Void) {
        FirebaseController.dataAtEndpoint("/users/\(user.identifier!)/tutors/") { (data) -> Void in
            if let json = data as? [String: AnyObject] {
                var subjects: [Int] = []
                var objectCount = 0
                for subjectJson in json {
                    let key = Int(subjectJson.0)
                    subjects.append(key!)
                    objectCount += 1
                    if objectCount == json.count {
                        completion(subjects)
                    } else {
                        objectCount += 1
                        if objectCount == json.count {
                            if subjects.count > 0 {
                                completion(subjects)
                            } else {
                                completion(nil)
                            }
                        }
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    static func authenticateUserWithToken(_ token: String, completion: @escaping (_ success: Bool, _ user: User?) -> Void) {
        FirebaseController.credentialForToken(token) { (credential) in
            FirebaseController.auth?.signIn(with: credential) { (user, error) in
                if error != nil {
                    completion(false, nil)
                } else {
                    UserController.userWithIdentifier(user!.uid, completion: { (user) -> Void in
                        if let user = user {
                            shared.currentUser = user
                            completion(true, user)
                        } else {
                            completion(true, nil)
                        }
                    })
                }
            }
        }
    }
    
    static func authenticateUserWithEmail(_ email: String, password: String, completion: @escaping (_ message: String?, _ user: User?) -> Void) {
        FirebaseController.auth?.signIn(withEmail: email, password: password) { (response, error) -> Void in
            if let error = error {
                FirebaseController.errorMessageForCode(error as NSError, completion: { (message) in
                    completion(message, nil)
                })
            } else {
                UserController.userWithIdentifier(response!.uid, completion: { (user) -> Void in
                    if let user = user {
                        shared.currentUser = user
                        completion(nil, user)
                    } else {
                        completion(nil, nil)
                    }
                })
            }
        }
    }
    
    static func logoutCurrentUser() {
        DefaultsController.removeValues()
        try! FirebaseController.auth?.signOut()
        shared.currentUser = nil
    }
    
}
