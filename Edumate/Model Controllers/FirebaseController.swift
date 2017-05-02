//
//  FirebaseController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/23/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation
import Firebase

class FirebaseController {
    
    static let base = FIRDatabase.database().reference()
    static let storage = FIRStorage.storage().reference(forURL: "gs://project-886768919900574861.appspot.com/")
    static let auth = FIRAuth.auth()
    
    static func dataAtEndpoint(_ endpoint: String, completion: @escaping (_ data: AnyObject?) -> Void) {
        let baseForEndpoint = FirebaseController.base.child(endpoint)
        baseForEndpoint.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.value is NSNull {
                completion(nil)
            } else {
                completion(snapshot.value as AnyObject?)
            }
        })
    }
    
    static func observeDataAtEndpoint(_ endpoint: String, completion: @escaping (_ data: AnyObject?) -> Void) {
        let baseForEndpoint = FirebaseController.base.child(endpoint)
        baseForEndpoint.observe(.value, with: { snapshot in
            if snapshot.value is NSNull {
                completion(nil)
            } else {
                completion(snapshot.value as AnyObject?)
            }
        })
    }
    
    static func credentialForToken(_ token: String, completion: (_ credential: FIRAuthCredential) -> Void) {
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: token)
        completion(credential)
    }
    
    static func errorMessageForCode(_ error: NSError, completion: (_ message: String?) -> Void) {
        var message = String()
        if let error = FIRAuthErrorCode(rawValue: error.code) {
            switch error {
            case .errorCodeNetworkError:
                message = "A network error occurred. Please try again later."
            case .errorCodeUserNotFound:
                message = "User not found."
            case .errorCodeInvalidEmail:
                message = "Please enter a valid email."
            case .errorCodeWrongPassword:
                message = "Wrong password. Please try again."
            case .errorCodeEmailAlreadyInUse:
                message = "Email already in use. Please enter a different email."
            case .errorCodeWeakPassword:
                message = "Passwords need to be at least 6 characters long."
            default:
                message = "There was a problem authenticating the account. Please try again later."
            }
            completion(message)
        } else {
            completion(nil)
        }
    }
    
}

protocol FirebaseType {
    var identifier: String? { get set }
    var endpoint: String { get }
    var jsonValue: [String: AnyObject] { get }
    
    init?(json: [String : AnyObject], identifier: String)
    
    mutating func save()
    func delete()
}

extension FirebaseType {
    mutating func save() {
        var endpointBase: FIRDatabaseReference
        if let identifier = self.identifier {
            endpointBase = FirebaseController.base.child(endpoint).child(identifier)
        } else {
            endpointBase = FirebaseController.base.child(endpoint).childByAutoId()
            self.identifier = endpointBase.key
        }
        endpointBase.updateChildValues(self.jsonValue)
    }
    
    func delete() {
        if let identifier = self.identifier {
            let endpointBase: FIRDatabaseReference = FirebaseController.base.child(endpoint).child(identifier)
            endpointBase.removeValue()
        }
    }
    
}
