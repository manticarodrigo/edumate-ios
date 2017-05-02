//
//  NotificationViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 12/9/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import OneSignal

class NotificationViewController: UIViewController {

    @IBOutlet weak var enableButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup enable button
        self.enableButton.stylize()
    }
    
    @IBAction func enableButtonPressed(_ sender: Any) {
        if OneSignalController.pushNotificationTurnedOn {
            self.displayAlert("Notifications Enabled", message: "You have already allowed notifications on this device.")
        } else {
            OneSignalController.register()
        }
    }

}
