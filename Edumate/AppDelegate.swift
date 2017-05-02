//
//  AppDelegate.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 6/1/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import Firebase
import OneSignal
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // MARK: - App Launch Methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Firebase Initialization
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        // FIRDatabase.setLoggingEnabled(true)
        // Initialize One Signal API
        /*OneSignal.initWithLaunchOptions(launchOptions, appId: "3d9bbcd9-2dc3-41f3-8400-ba64092e2d29", handleNotificationReceived: { (notification) in
            if let notification = notification {
                print("Received Notification: \(notification.payload.notificationID)")
                // TODO: Increase chat badge count
            }
        }, handleNotificationAction: { (result) in
            if let result = result {
                self.showNotification(with: result)
            }
        }, settings: [kOSSettingsKeyAutoPrompt : false, kOSSettingsKeyInFocusDisplayOption : OSNotificationDisplayType.none])
        // Fetch user id & push token
        OneSignal.idsAvailable({ (userId, pushToken) in
            if let userId = userId {
                print("UserId:%@", userId)
            }
            if let pushToken = pushToken {
                print("pushToken:%@", pushToken)
            }
        })*/
        // Load university data
        self.generateSearchData()
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
    
    func application(_ application: UIApplication, open url: URL,
                     sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance()
            .application(application, open: url,
                         sourceApplication: sourceApplication, annotation: annotation)
    }
    
    // MARK: - Remote Notification Methods
    
    func showNotification(with result: OSNotificationOpenedResult) {
        // This block gets called when the user reacts to a notification received
        if let payload = result.notification.payload {
            // Fetch additional data
            if let additionalData = payload.additionalData {
                if let identifier = additionalData["identifier"] as? String {
                    self.window?.rootViewController?.tabBarController?.selectedIndex = 1
                    UserController.userWithIdentifier(identifier, completion: { (user) in
                        if let user = user {
                            ChatController.chatWithUser(user, completion: { (chat) in
                                if let chat = chat {
                                    let chatDict = ["User": user, "Chat": chat] as [String : Any]
                                    self.window?.rootViewController?.tabBarController?.selectedViewController?.performSegue(withIdentifier: "chat", sender: chatDict)
                                }
                            })
                        }
                    })
                }
                if let actionSelected = additionalData["actionSelected"] as? String {
                    print(actionSelected)
                }
            }
            // Fetch title and body
            if let title = payload.title, let body = payload.body {
                print("\(title): \(body)")
            }
        }
    }
    
    // MARK: - SearchTextField Data Methods
    
    func generateSearchData() {
        SearchController.observeUsers()
        SearchController.observeCourses()
        SearchController.generateUniversities()
    }
    
    // MARK: - App State Methods
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
}

