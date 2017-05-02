//
//  DefaultsController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 11/14/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation

class DefaultsController {
    
    static func fetchSubjectInt(completion: (_ subjectInt: Int?) -> Void) {
        if let subjectInt = UserDefaults.standard.object(forKey: "userSubject") as? Int {
            completion(subjectInt)
        } else {
            completion(nil)
        }
    }
    
    static func setSubjectInt(int: Int) {
        UserDefaults.standard.set(int, forKey: "userSubject")
    }
    
    static func fetchTutorBool(completion: (_ tutorBool: Bool?) -> Void) {
        if let tutorBool = UserDefaults.standard.object(forKey: "userTutorRestricted") as? Bool {
            completion(tutorBool)
        } else {
            completion(nil)
        }
    }
    
    static func setTutorBool(bool: Bool) {
        UserDefaults.standard.set(bool, forKey: "userTutorRestricted")
    }
    
    static func fetchSchoolBool(completion: (_ schoolBool: Bool?) -> Void) {
        if let schoolBool = UserDefaults.standard.object(forKey: "userSchoolRestricted") as? Bool {
            completion(schoolBool)
        } else {
            completion(nil)
        }
    }
    
    static func setSchoolBool(bool: Bool) {
        UserDefaults.standard.set(bool, forKey: "userSchoolRestricted")
    }
    
    static func fetchRadiusInt(completion: (_ radiusInt: Int?) -> Void) {
        if let radiusInt = UserDefaults.standard.object(forKey: "userRadius") as? Int {
            completion(radiusInt)
        } else {
            completion(nil)
        }
    }
    
    static func setRadiusInt(int: Int) {
        UserDefaults.standard.set(int, forKey: "userRadius")
    }
    
    static func fetchIntroBool(completion: (_ bool: Bool?) -> Void) {
        if let introBool = UserDefaults.standard.object(forKey: "userIntroDone") as? Bool {
            completion(introBool)
        } else {
            completion(nil)
        }
    }
    
    static func setIntroBool(bool: Bool) {
        UserDefaults.standard.set(bool, forKey: "userIntroDone")
    }
    
    static func fetchPushBool(completion: (_ bool: Bool?) -> Void) {
        if let pushBool = UserDefaults.standard.object(forKey: "userPushPrompted") as? Bool {
            completion(pushBool)
        } else {
            completion(nil)
        }
    }
    
    static func setPushBool(bool: Bool) {
        UserDefaults.standard.set(bool, forKey: "userPushPrompted")
    }
    
    static func removeValues() {
        UserDefaults.standard.set(nil, forKey: "userSubject")
        UserDefaults.standard.set(nil, forKey: "userTutorRestricted")
        UserDefaults.standard.set(nil, forKey: "userSchoolRestricted")
        UserDefaults.standard.set(nil, forKey: "userRadius")
        UserDefaults.standard.set(nil, forKey: "userIntroDone")
        UserDefaults.standard.set(nil, forKey: "userPushPrompted")
    }
    
}
