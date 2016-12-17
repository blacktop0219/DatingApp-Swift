//
//  LocationServicesDisabledController.swift
//  Blurv
//
//  Created by Arthur Belair on 2016-02-08.
//  Copyright © 2016 Guarana Technologies Inc. All rights reserved.
//

import UIKit
import CoreLocation

class LocationServicesDisabledController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LocationServicesDisabledController.checkLocationStatus), name: NOTIFICATION_LOCATION_SERVICES_STATUS, object: nil)
        
        // Do any additional setup after loading the view.
    }

    @IBAction func openSettings(sender: AnyObject) {
        if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(appSettings)
        }
    }

    func checkLocationStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

}
