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
import Alamofire
import AlamofireImage

class DestinationViewController: UIViewController {
    
    @IBOutlet weak var locationImage: UIImageView!
    @IBOutlet weak var mainImage: UIImageView!
    
    @IBOutlet weak var locationNameView: UIView!
    @IBOutlet weak var ratingView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var rating: CosmosView!
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
            UIColor(red: 110/255.0, green: 110/255.0, blue: 110/255.0, alpha: 0.75)
        locationImage.layer.cornerRadius = locationImage.frame.width/2
        locationImage.layer.borderColor = borderColor.CGColor
        locationImage.layer.borderWidth = 5
        locationImage.clipsToBounds = true
        locationNameView.addSubview(locationLabel)
        locationImage.addSubview(locationNameView)
        locationImage.insertSubview(mainImage, atIndex: 0)
        
        locationImage.addSubview(ratingView)
        ratingView.backgroundColor = (locationIsOpenNow()) ?
            //medium seaweed
            UIColor(red:60/255.0, green:179/255.0, blue:113/255.0, alpha: 0.8):
            //medium firebrick
            UIColor(red:205/255.0, green:35/255.0, blue:35/255.0, alpha:0.8)
        locationNameView.backgroundColor =
        UIColor(red:197/255.0, green:193/255.0, blue:170/255.0, alpha: 0.75)
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
                    
                    return (currentlyOpen == 0) ? false:true
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
    
    func LabelSetup() {
        if let places = results {
            locationLabel.text = places[numberOfShakesDetected]["name"] as? String
            locationLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    
    //MARK: - Animations
    func exitLocationView() {
        self.imageQuery("gas station",
                        atIndex: self.numberOfShakesDetected)
        UIView.animateWithDuration(0.45, delay: 0.0, options: .CurveEaseOut, animations: {
            self.locationImage.center.x -= self.locationImage.frame.width
            }, completion: {
                (completed) -> Void in
                if completed {
                    self.mainImage.image = nil
                    self.imageSetup()
                    self.LabelSetup()
                    self.acquireRatingForLocation()
                    self.enterLocationView()
                    self.setIcons()
                }
        })
    }
    
    func enterLocationView() {
        UIView.animateWithDuration(0.45, delay: 0.05, options: .CurveEaseIn, animations: {
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
                exitLocationView()
                }
            }
        }
        
    }
    
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
        imageQuery("gas station", atIndex: numberOfShakesDetected)
    }
    
    //MARK: - Image Query

    func imageQuery(location: String, atIndex: Int) {
        if let names = locationNames {
            let name: String = (names.count > atIndex) ?
                "\(names[atIndex]!)":"\(location)"
            let query: String?
            query = (name.contains(location)) ?
                "\(name)": "\(name) "+"\(location)"
            if let search = query {
                retrieveImage(search)
            }
        }
    }
    
    func retrieveImage(query: String) {
        Search.fetchImages(query, completion: {
            (data) -> Void in
            if let data = data {
                let result: [NSDictionary]? = data["items"] as? [NSDictionary]
                if let result = result {
                    let desired: NSDictionary =
                        (result.count > 0) ? result[0] as NSDictionary:[:]
                    let url: String? = (desired.count > 0) ?
                        desired["link"] as? String: ""
                    if let URL = url {
                        self.setImage(URL)
                    }
                }
            }
        })
    }
    
    func setImage(url: String) {
        Alamofire.request(.GET, url).responseImage(completionHandler: {
            response in
            // TODO: Handle errors
            if let image = response.result.value {
                self.mainImage.image = image
                self.mainImage.clipsToBounds = true
            }
        })
        
    }
}




