//
//  LocationRequestViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/20/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import CoreLocation

class LocationRequestViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    @IBOutlet weak var locationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup location button
        self.locationButton.stylize()
    }
    
    @IBAction func locationButtonPressed(_ sender: AnyObject) {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined:
                // Ask for authorization from the user to get location
                self.locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                // Direct users to settings to enable location services
                self.displayAlert("Location Disabled", message: "Navigate to you device's settings page and scroll down to the Edumate app to enable location services")
            case .authorizedAlways, .authorizedWhenInUse:
                // Location authorized
                self.displayAlert("Location Enabled", message: "You have already allowed location access on this device.")
            }
        }
    }

}
