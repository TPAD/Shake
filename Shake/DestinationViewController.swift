//
//  DestinationViewController.swift
//  Shake
//
//  Created by Tony Padilla on 5/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import Cosmos

class DestinationViewController: UIViewController {
    
    @IBOutlet weak var locationImage: UIImageView!
    @IBOutlet weak var locationNameView: UIView!
    @IBOutlet weak var ratingView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var rating: CosmosView!
  

    
    //var locationLabel: UILabel = UILabel(frame: CGRectMake(0, 0 ,0 ,0))
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var leftIcon: UIImageView!
    @IBOutlet weak var centerIcon: UIImageView!
    @IBOutlet weak var rightIcon: UIImageView!
    @IBOutlet weak var middleIconMid: NSLayoutConstraint!
    var centerIconMidX: CGFloat?
    
    var locationNames: [String?]?
    var address: String?
    var userLocation: CLLocation?
    var userCoords: CLLocationCoordinate2D? {
        didSet {
            if userCoords != nil {
                userLocation = CLLocation(latitude: userCoords!.latitude,
                                          longitude: userCoords!.longitude)
            }
        }
    }
    var results: Array<NSDictionary>?
    var iconCount: Int = 0
    var numberOfShakesDetected: Int = 0
    
    // MARK: - Icons
    
    func locationHasCarRepair() -> Bool {
        if let places = results {
            if let types = places[numberOfShakesDetected]["types"] as? Array<String>{
                if types.contains("car_repair") { return true }
                else { return false }
            }
        }
        return false
    }
    
    func locationHasATM() -> Bool {
        if let places = results {
            if let types = places[numberOfShakesDetected]["types"] as? Array<String>{
                if types.contains("atm") { return true }
                else { return false }
            }
        }
        return false
    }
    
    func locationIsConvenienceStore() -> Bool {
        if let places = results {
            if let types = places[numberOfShakesDetected]["types"] as? Array<String>{
                if types.contains("convenience_store") { return true }
                else { return false }
            }
        }
        return false
    }
    
    func locationIcons(setIcons: (repair: Bool, ATM: Bool, store: Bool) -> Void) {
        let carRepair: Bool = locationHasCarRepair()
        let atm: Bool = locationHasATM()
        let isStore: Bool = locationIsConvenienceStore()
        if carRepair && atm && isStore {
            self.iconCount = 3
        } else if carRepair && atm || atm && isStore || carRepair && isStore {
            self.iconCount = 2
        } else if carRepair || atm || isStore {
            self.iconCount = 1
        } else {
            self.iconCount = 0
        }
        setIcons(repair: carRepair, ATM: atm, store: isStore)
    }
    
    func setIcons() {
        locationIcons({
            (repair, ATM, store) -> Void in
            if self.iconCount == 3 {
                self.centerIcon.alpha = 1
                self.rightIcon.alpha = 1
                self.leftIcon.alpha = 1
                if let midX = self.centerIconMidX {
                    self.middleIconMid.constant = midX
                }
                self.leftIcon.image = UIImage(named: "cafe-71")
                self.centerIcon.image = UIImage(named: "atm-71")
                self.rightIcon.image = UIImage(named: "shopping-71")
        
            } else if self.iconCount == 2 {
                self.leftIcon.alpha = 0
                self.centerIcon.alpha = 1
                self.rightIcon.alpha = 1
                if let midX = self.centerIconMidX {
                    self.middleIconMid.constant = midX
                }
                self.middleIconMid.constant -= (self.centerIcon.frame.width/2 + 2.5)
                if repair && ATM {
                    self.centerIcon.image = UIImage(named: "car_repair-71")
                    self.rightIcon.image = UIImage(named: "atm-71")
                } else if repair && store {
                    self.centerIcon.image = UIImage(named: "car_repair-71")
                    self.rightIcon.image = UIImage(named: "shopping-71")
                } else {
                    self.centerIcon.image = UIImage(named: "shopping-71")
                    self.rightIcon.image = UIImage(named: "atm-71")
                }
            } else if self.iconCount == 1 {
                self.leftIcon.alpha = 0
                self.rightIcon.alpha = 0
                self.centerIcon.alpha = 1
                if let midX = self.centerIconMidX {
                    self.middleIconMid.constant = midX
                }
                if repair && !ATM && !store {
                    self.centerIcon.image = UIImage(named: "car_repair-71")}
                else if ATM && !repair && !store {
                    self.centerIcon.image = UIImage(named: "atm-71")}
                else if store && !ATM && !repair {
                    self.centerIcon.image = UIImage(named: "shopping-71")}
            } else {
                self.leftIcon.alpha = 0
                self.rightIcon.alpha = 0
                self.centerIcon.alpha = 0
            }
        })
    }
    
    // MARK: - Setup
    
    func imageSetup() {
        let borderColor =
            UIColor(red: 110/255.0, green: 110/255.0, blue: 110/255.0, alpha: 0.5)
        locationImage.layer.cornerRadius = locationImage.frame.width/2
        locationImage.layer.borderColor = borderColor.CGColor
        locationImage.layer.borderWidth = 5
        locationImage.clipsToBounds = true
        locationNameView.alpha = 0.75
        locationNameView.addSubview(locationLabel)
        locationImage.addSubview(locationNameView)
        
        locationImage.addSubview(ratingView)
        ratingView.alpha = 0.6
        ratingView.backgroundColor = (locationIsOpenNow()) ?
            UIColor.greenColor():UIColor.redColor()
        
        /*if let places = results {
         let id = places[numberOfShakesDetected]["place_id"] as? String
         if let placeID = id {
         dispatch_async(dispatch_get_main_queue(), {
         GMSPlacesClient.sharedClient().lookUpPhotosForPlaceID(placeID) {
         (photos, error) -> Void in
         if let error = error {
         // TODO: handle the error.
         print("Error: \(error.description)")
         } else {
         if let photo = photos?.results.first {
         self.loadImageForMetadata(photo)
         }
         }}
         })
         }
         }*/
    }
    
    func acquireRatingForLocation() {
        self.rating.settings.fillMode = .Precise
        if let places = self.results {
            if let rating = places[numberOfShakesDetected]["rating"] {
                self.rating.rating = rating as! Double
            } else {
                self.rating.rating = 2.5
            }
        }
    }
    
    func locationIsOpenNow() -> Bool {
        
        if let places = results {
            if let hours = places[numberOfShakesDetected]["opening_hours"]
                as? NSMutableDictionary {
                if let currentlyOpen = hours["open_now"] as? Int {
                    switch(currentlyOpen) {
                    case 0:
                        return false
                    case 1:
                        return true
                    default:
                        return false
                    }
                }
            }
        }
        return false
    }
    
    func distanceFromLocation() {
        if let places = results {
            if let geometry = places[numberOfShakesDetected]["geometry"] {
                if let location = geometry["location"] as? NSMutableDictionary {
                    let lat = location["lat"] as! Double
                    let lng = location["lng"] as! Double
                    let locationA = CLLocation(latitude: lat, longitude: lng)
                    if let locationB = self.userLocation {
                        let distance = locationB.distanceInMilesFromLocation(locationA)
                        let dString: String = String(format: "%.2f", distance)
                        self.distanceLabel.text = "\(dString)mi"
                    }
                    
                }
            }
        }
    }
    
    func imageForLocation() {
        if let places = results {
            if let geometry = places[numberOfShakesDetected]["geometry"] {
                if let location = geometry["location"] as? NSMutableDictionary {
                    let lat: Double = location["lat"] as! Double
                    let lng: Double = location["lng"] as! Double
                    let size: CGSize = self.locationImage.frame.size
                    let placeLocation =
                        CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    if let url =
                        Search.getStreetViewsURL(placeLocation, size: size) {
                          
                    }
                }
            }
        }
        
    }
    
    func LabelSetup() {
        if let places = results {
            locationLabel.text = places[numberOfShakesDetected]["name"] as? String
            locationLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    
    //MARK: - Animations
    func exitView() {
        UIView.animateWithDuration(0.6, delay: 0.0, options: .CurveEaseOut, animations: {
            self.locationImage.center.x -= self.locationImage.frame.width
            }, completion: {
                (completed) -> Void in
                if completed {
                    self.imageSetup()
                    self.LabelSetup()
                    self.acquireRatingForLocation()
                    self.enterView()
                    self.setIcons()
                }
        })
    }
    
    func enterView() {
        UIView.animateWithDuration(0.6, delay: 0.0, options: .CurveEaseIn, animations: {
            self.locationImage.center.x += self.locationImage.frame.width
            self.distanceFromLocation()
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    // MARK: - OVERRIDDEN FUNCTIONS
    
    // MARK: - Shake detection
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        //super.motionBegan(motion, withEvent: event)
        if (self.isViewLoaded() == true && self.view.window != nil) {
            if let motion = event {
                if motion.subtype == .MotionShake {
                    if let max = self.results?.count {
                        if numberOfShakesDetected < max-1 {
                            numberOfShakesDetected += 1
                        } else {
                            numberOfShakesDetected = 0
                        }
                    }
                exitView()
                }
            }
        }
        
    }
    
    /*override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        super.motionBegan(motion, withEvent: event)
        if (self.isViewLoaded() == true && self.view.window != nil) {
            if let motion = event {
                if motion.subtype == .MotionShake {
                    
                }
            }
        }
    }*/
    
    //MARK: - Views
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.centerIconMidX = middleIconMid.constant
        setIcons()
        imageSetup()
        LabelSetup()
        distanceFromLocation()
        acquireRatingForLocation()
        imageForLocation()
        //print(locationNames)
    }
    
    /*override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        dispatch_async(dispatch_get_main_queue(), {
            self.locationLabel.center.x = self.locationNameView.center.x
        })
        
    }*/
}



