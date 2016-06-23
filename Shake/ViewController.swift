//
//  ViewController.swift
//  Shake
//
//  Created by Tony Padilla on 5/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var locationName: UILabel!
    
    var locationManager: CLLocationManager!
    var results: Array<NSDictionary>?
    var locationNames: [String?]?
    var address: String?
    var readyToSegue: Bool = false
    var viewIsReadyToDisplay: Bool = false
    var status = CLLocationManager.authorizationStatus()
    var userCoord: CLLocationCoordinate2D?
    
    // MARK: - Override Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationName.text = "Gas Station"
        NSNotificationCenter.defaultCenter().addObserver(self, selector:
        #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)),
        name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:
        #selector(ViewController.applicationWillEnterBackground(_:)),
        name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        setBackgroundImage()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if !Reachability.isConnected() {
            self.view.offlineViewAppear()
            print("Not connected")
        }
        initialLoadView()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        locationGetterSetup()
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        super.motionBegan(motion, withEvent: event)
        if (self.isViewLoaded() == true && self.view.window != nil) {
            if let motion = event {
                if motion.subtype == .MotionShake && readyToSegue {
                    UIView.animateWithDuration(0.4, delay: 0.0, options:
                        .CurveEaseOut, animations: {
                            self.locationName.alpha = 0
                            self.locationName.horizontalShakeAnimation()
                        }, completion: { _ in
                            self.goToDetail(self)
                    })
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? DestinationViewController {
            if let data = results {
                destination.userCoords = self.userCoord
                destination.address = self.address
                destination.results = data
                destination.locationNames = self.locationNames
            }
        }
    }
    
    //MARK: - 
    
    func locationGetterSetup() {
        if status != .Restricted && status != .Denied {
            self.locationManager = CLLocationManager()
            if status == .NotDetermined {
                self.locationManager.requestWhenInUseAuthorization()
            }
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
                
            }
        } else if status == .AuthorizedAlways {
            print("App should not have this control")
        } else {
            // navigate to settings so that user may turn on location services
            Helper.navigateToSettingsViaAlert(self)
        }
    }

    func goToDetail(sender: AnyObject) {
        self.performSegueWithIdentifier("toDetail", sender: sender)
    }
    
    func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D) {
        
        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(coordinate, completionHandler: {
            response, error in
            if error == nil {
                if let address = response?.firstResult() {
                    let lines = address.lines! as [String]
                    self.address = lines.joinWithSeparator("\n")
                }
            } else {
                print("Address error: \(error)")
            }
        })
    }
    
    func setBackgroundImage() {
        let view: UIImageView = UIImageView(frame: self.view.frame)
        view.image = UIImage(named: "gas_station")
    
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //fill the view
        blurEffectView.frame = self.view.frame
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.addSubview(blurEffectView)
        
        self.view.insertSubview(view, atIndex: 0)
    }
    
    func applicationWillEnterForeground(notification: NSNotification) {
        print("did enter foreground")
        if status == .Restricted || status == .Denied {
            Helper.relaunchAppNotification(self)
        }
        if !Reachability.isConnected() {
            self.view.offlineViewDisappear()
            self.view.offlineViewAppear()
            print("not connected")
        } else {
            self.view.offlineViewDisappear()
        }
    }
    
    func applicationWillEnterBackground(notification: NSNotification) {
        print("did enter background")
    }
    
    @IBAction func testSegue(sender: AnyObject) {
        self.performSegueWithIdentifier("toDetail", sender: self)
    }
    
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

// MARK: - Location Manager Delegate

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus
        status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
        
            let value: CLLocationCoordinate2D = (location.coordinate)
            self.userCoord = location.coordinate
            reverseGeocodeCoordinate(value)
            let query: String = "gas_station"
            
            if status == .AuthorizedWhenInUse && Reachability.isConnected() {
                if let location = manager.location {
                    if let url = Search.getLocationsURL(query, location: location) {
                        googleSearch(url)
                    }
                }
            }
        }
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Manager Error: \(error)")
    }
}

//MARK: - Initial Load Animation

extension ViewController {
    
    func initialLoadView() {
        
        let mainView: UIView = UIView(frame: self.view.frame)
        mainView.backgroundColor = UIColor.whiteColor()
        let width: CGFloat = 0.35*(mainView.frame.width)
        let logoView: UIImageView =
            UIImageView(frame: CGRectMake(0, 0, width, width))
        logoView.center = mainView.center
        logoView.image = UIImage(named: "ShakeLogo")
        
        mainView.addSubview(logoView)
        self.view.addSubview(mainView)
        initialLoadAnimation(mainView, image: logoView)
    }
    
    func initialLoadAnimation(view: UIView, image: UIImageView) {
        image.rotationAnimation()
        
        let delayInSeconds: Int64  = 800000000;
        
        let popTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds);
        
        dispatch_after(popTime, dispatch_get_main_queue(), {
            UIView.animateWithDuration(0.80, delay: 0.05, options: .CurveEaseInOut, animations: {
                image.center.y -= (view.frame.height)
                }, completion: {
                    _ -> Void in
                    self.fadeOut(view)
            })
        });
    }
    
    func fadeOut(view: UIView) {
        UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseInOut, animations: {
            view.alpha = 0
            }, completion: {
                _ -> Void in
                view.removeFromSuperview()
        })
        
    }
}










