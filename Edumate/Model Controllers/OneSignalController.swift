//
//  OneSignalController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 12/10/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import OneSignal

class OneSignalController {
    
    static var pushNotificationTurnedOn : Bool {
        get {
            if let types = UIApplication.shared.currentUserNotificationSettings?.types {
                if types.rawValue > 0 {
                    // Application is subscribed to push notifications
                    return true
                } else {
                    // Application is NOT subscribed to push notifications
                    return false
                }
            } else  {
                return false
            }
        }
    }
    
    static func register() {
        OneSignal.registerForPushNotifications()
        DefaultsController.setPushBool(bool: true)
    }
    
    static func devicePushToken(completion: @escaping (_ token: String?) -> Void) {
        OneSignal.idsAvailable { (userId, pushToken) in
            if let userId = userId {
                print("pushToken: \(userId)")
                completion(userId)
            } else {
                completion(nil)
            }
        }
    }
    
    static func sendTags(tags: [String : Any]) {
        OneSignal.sendTags(tags)
    }
    
    static func getTags(tags: [String], completion: @escaping (_ tags: [String : Any]?) -> Void) {
        OneSignal.getTags({ (tags) in
            if let tags = tags as? [String : Any] {
                completion(tags)
            }
        }, onFailure: { (error) in
            if let error = error {
                print("Error getting tags - \(error.localizedDescription)")
            }
        })
    }
    
    static func deleteTags(tags: [String]) {
        OneSignal.deleteTags(tags)
    }
    
    static func notify(user: User, text: String, player_id: String) {
        OneSignal.postNotification(["app_id" : "3d9bbcd9-2dc3-41f3-8400-ba64092e2d29",
                                    "headings" : ["en": user.name],
                                    "contents" : ["en": text],
                                    "include_player_ids" : [player_id],
                                   "data": ["identifier" : user.identifier!]])
    }
    
    static func setSubscription(bool: Bool) {
        OneSignal.setSubscription(bool)
    }
    
}
