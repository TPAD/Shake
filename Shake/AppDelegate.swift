//
//  AppDelegate.swift
//  Shake
//
//  Created by Tony Padilla on 5/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

import UIKit
import CoreData
import GoogleMaps
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager!
    var status = CLLocationManager.authorizationStatus()
    var userCoord: CLLocationCoordinate2D?
    var dest: CLLocationCoordinate2D?
    var angle: Double?
    
    var distFromDest: Double?
    
    func getApiKey() -> String {
        return "AIzaSyCBckYCeXQ6j_voOmOq7UHuWqWjHUYEz7E"
    }
    
    /* 
     *  Initializes location manager given the correct permissions
     *  Requests authorization if needed
     *
     */
    func locationGetterSetup() {
        if status != .restricted && status != .denied {
            self.locationManager = CLLocationManager()
            self.locationManager.requestWhenInUseAuthorization()
        }
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.distanceFilter = 20.0
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    //MARK: - Location Manager Delegate Functions
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization
        status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.userCoord = location.coordinate
        }
    }
    
    // TODO: - handle this error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager error: \(error)")
    }
    
    /*
     *  This method allows the user to use the compass surrounding
     *  the Location object in ViewController
     *
     */
    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {
        //print("suh dood")
        let here: CLLocationCoordinate2D = manager.location!.coordinate
        if let destination = dest {
            angle = here.angleTo(destination: destination)
            // heading information is necessary to calculate rotation angle of compass
            var h = newHeading.magneticHeading
            let h2 = newHeading.trueHeading // will be -1 if we have no location info
            if h2 >= 0 { h = h2 }
            
            // DestinationViewController is the one that requests heading updates
            if let destinationVC: DestinationViewController =
                Helper.topMostViewController() as? DestinationViewController {
                if let deg = angle {
                    // match compass rotation to the angle calculated angle
                    UIView.animate(withDuration: 0.4, animations: {
                        destinationVC.compass!.transform =
                            CGAffineTransform(rotationAngle: CGFloat((deg - h) * M_PI/180))
                    })
                    let dest: CLLocation = CLLocation(latitude: destination.latitude,
                    longitude: destination.longitude)
                    // update distance between user and location navigated to
                    destinationVC.updateDistance(manager, destination: dest)
                }
            }
         }
    }
    
    //MARK: - Application functions
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey(getApiKey())
        locationGetterSetup()
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("resigned active")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("will Enter Foreground")
        if let destinationVC: DestinationViewController =
            Helper.topMostViewController() as? DestinationViewController {
            destinationVC.locationManagerSetup()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("did become active")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        //self.saveContext()
    }
}



