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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager!
    var address: String?
    var status = CLLocationManager.authorizationStatus()
    var userCoord: CLLocationCoordinate2D?
    var destination: CLLocationCoordinate2D?
    var angle: Double?
    
    var distFromDest: Double?
    
    func getApiKey() -> String {
        return "AIzaSyCBckYCeXQ6j_voOmOq7UHuWqWjHUYEz7E"
    }
    
    func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(coordinate, completionHandler: {
            response, error in
            if error == nil {
                if let address = response?.firstResult() {
                    let lines = address.lines! as [String]
                    self.address = lines.joined(separator: "\n")
                    //self.locationManager.stopUpdatingLocation()
                }
            } else {
                print("Address error: \(error)")
            }
        })
    }
    
    func locationGetterSetup() {
        if status != .restricted && status != .denied {
            self.locationManager = CLLocationManager()
            self.locationManager.requestWhenInUseAuthorization()
        }
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.distanceFilter = 20.0
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
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
            let value: CLLocationCoordinate2D = (location.coordinate)
            self.userCoord = location.coordinate
            reverseGeocodeCoordinate(value)
            // from deprecated function
            let here: CLLocationCoordinate2D = location.coordinate
            if let destination = destination {
                calculateUserAngle(here, destination: destination)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager error: \(error)")
    }

    func topMostViewController() -> UIViewController? {
        let topController: UIViewController? =
            UIApplication.shared.keyWindow?.rootViewController
        if let top = topController {
            let presentedController: UIViewController? = top.presentedViewController
            if let top_most = presentedController {
                return top_most
            }
        }
        return nil
        
    }
    
    func calculateUserAngle(_ current: CLLocationCoordinate2D,
                            destination: CLLocationCoordinate2D) {
        var x: Double = 0
        var y: Double = 0
        var deg: Double = 0
        var delLon: Double = 0
        
        delLon = destination.longitude - current.longitude
        y = sin(delLon) * cos(destination.latitude)
        x = cos(current.latitude) * sin(destination.latitude) -
            sin(current.latitude) * cos(destination.latitude)*cos(delLon)
        deg = atan2(y, x).radiansToDegrees as! Double
        
        if (deg < 0) {
            deg = -deg
        } else {
            deg = 360 - deg
        }
        angle = deg
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
        print("did Enter Background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("will Enter Foreground")
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



