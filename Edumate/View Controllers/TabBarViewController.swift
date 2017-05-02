//
//  TabBarViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 11/13/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Select courses page
        self.selectedViewController = self.viewControllers![2]
        
        // Remove line on top of tab bar
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        
        // Sets the default color of the background of the UITabBar
        UITabBar.appearance().barTintColor = UIColor.white
        
        // Sets the default color of the icon & tile of unselected UITabBarItem
        let unselectedColor = UIColor.lightGray
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: unselectedColor], for: .normal)
        for item in self.tabBar.items! {
            if let image = item.image {
                let coloredImage = image.withColor(color: unselectedColor)
                item.image = coloredImage.withRenderingMode(.alwaysOriginal)
            }
        }
        
        // Sets the default color of the icon & title of the selected UITabBarItem
        let selectedColor = Constants.data.lightBlue
        UITabBar.appearance().tintColor = selectedColor
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.darkGray], for: .selected)
        
        // Sets the background color of the selected UITabBarItem
        let tabCount = CGFloat(self.tabBar.items!.count)
        UITabBar.appearance().selectionIndicatorImage = UIImage().createSelectionIndicator(color: selectedColor, size: CGSize(width: tabBar.frame.width/tabCount, height: tabBar.frame.height), lineWidth: 2)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Check for current user
        if let currentUser = UserController.shared.currentUser {
            self.tabBar.items![4].title = "\(currentUser.firstName())"
            /*DefaultsController.fetchPushBool(completion: { (prompted) in
                if let prompted = prompted {
                    if !prompted, !OneSignalController.pushNotificationTurnedOn {
                        OneSignalController.register()
                    }
                } else if !OneSignalController.pushNotificationTurnedOn {
                    OneSignalController.register()
                }
            })*/
        } else {
            self.selectedViewController = self.viewControllers![2]
            self.performSegue(withIdentifier: "login", sender:nil)
        }
    }

}
