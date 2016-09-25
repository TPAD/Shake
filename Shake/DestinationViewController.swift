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
import Alamofire
import AlamofireImage

class DestinationViewController: UIViewController {
    
    @IBOutlet weak var distanceLabel: UILabel!
    var compass: UIImageView?
    
    weak fileprivate var appDelegate: AppDelegate? =
        UIApplication.shared.delegate as? AppDelegate
    
    let blue: UIColor =
        UIColor(red: 78/255.0, green:147/255.0, blue:222/255.0, alpha: 1.0)
    let green: UIColor =
        UIColor(red:70/255.0, green:179/255.0, blue:173/255.0, alpha: 1.0)
    
    var locationView: LocationView?
    
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
    var locationToSearch: String = "gas station"
    var locationPhoneNumber: String?
    var collectionView: UICollectionView?
    
    func instantiateCustomView() {
        let y: CGFloat = (0.15)*self.view.frame.height
        let x: CGFloat = (0.05)*self.view.frame.width
        let width: CGFloat = (0.9)*self.view.frame.width
        
        let frame: CGRect = CGRect(x: x, y: y, width: width, height: width)
        locationView = LocationView(frame: frame)
        locationView!.dataSource = self
        locationView!.delegate = self
        locationView!.loadData()
        self.view.addSubview(locationView!)
    }
    
    // MARK: - Setup
    
    func distanceFromLocation() {
        if let places = results {
            if let geometry = places[numberOfShakesDetected]["geometry"] as? NSMutableDictionary {
                if let location = geometry["location"] as? NSMutableDictionary {
                    let lat = location["lat"] as! Double
                    let lng = location["lng"] as! Double
                    let locationA = CLLocation(latitude: lat, longitude: lng)
                    if let appDelegate = appDelegate {
                        appDelegate.destination = locationA.coordinate
                    }
                    if let locationB = self.userLocation {
                        print(self.userLocation)
                        let distance = locationB.distanceInMilesFromLocation(locationA)
                        let dString: String = String(format: "%.2f", distance)
                        self.distanceLabel.text = "\(dString)mi"
                    }
                }
            }
        }
    }
    
    func updateDistance(_ manager: CLLocationManager, destination: CLLocation) {
        Helper.GlobalMainQueue.async(execute: {
            if let location: CLLocation = manager.location {
                let destination: CLLocation = destination
                let distance = location.distanceInMilesFromLocation(destination)
                let dString: String = String(format: "%.2f", distance)
                self.distanceLabel.text = "\(dString)mi"
            }
        })
    }
    
    
    //MARK: - Animations
    func exitLocationView() {
        UIView.animate(withDuration: 0.45, delay: 0.0, options: .curveEaseOut, animations: {
            self.locationView!.center.x -= self.locationView!.frame.width
            }, completion: {
                (completed) -> Void in
                if completed {
                    self.locationView?.loadData()
                    self.enterLocationView()
                }
        })
    }
    
    func enterLocationView() {
        UIView.animate(withDuration: 0.45, delay: 0.05, options: .curveEaseIn, animations: {
            self.locationView!.center.x += self.locationView!.frame.width
            self.distanceFromLocation()
            }, completion: nil)
    }
    
   func returnPhoneNumber(from data: NSDictionary? ) {
        if let data = data {
            let results: NSDictionary? = data["result"] as? NSDictionary
            if let result = results {
                self.locationPhoneNumber =
                    result["formatted_phone_number"] as? String
            }
        }
    }
    
    func callAction() {
        if let num = locationPhoneNumber?.numberFormattedForCall() {
            if let url = URL(string: "tel://\(num)") {
                UIApplication.shared.open(url, completionHandler: nil)
            }
        } else {
            // TODO: alert of sorts
            print("Action can't be completed RN")
        }
    }
    
    func callAlert(onView view: LocationView, sender: UISwipeGestureRecognizer) {
        if let names = locationNames {
            let name = names[numberOfShakesDetected]! as String
            let title: String = "Call \(name)?"
            let alertController: UIAlertController
                = UIAlertController(title: title, message: "",
                                                    preferredStyle: .actionSheet)
            let yes = UIAlertAction(title: "Ok", style: .default, handler: {
                (action) -> Void in
                self.callAction()
            })
            //Needs a handler
            let nah = UIAlertAction(title: "No", style: .cancel, handler: {
                (action) -> Void in
                view.undoSwipe(onView: view.dualView!, sender: sender)
            })
            alertController.addAction(yes)
            alertController.addAction(nah)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func compassSetup(_ view: LocationView) {
        compass = UIImageView(frame: view.bounds)
        compass!.image = UIImage(named: "compass")
        compass!.center.x = view.center.x
        compass!.center.y = view.center.y
        compass!.bounds.size.height += 80
        compass!.bounds.size.width  += 80
        self.view.insertSubview(compass!, belowSubview: view)
    }
    
    func navigationAlert(onView view: LocationView, sender: UISwipeGestureRecognizer) {
        let title: String = "Navigation Mode"
        let alertController: UIAlertController =
            UIAlertController(title: title, message: "",
                              preferredStyle: .actionSheet)
        
        let onFoot: UIAlertAction = UIAlertAction(title: "On Foot",
                                                  style: .default,
            handler: {
                (action) -> Void in
                self.compassSetup(view)
                self.locationManagerSetup()
                                                    
        })
        let nah: UIAlertAction = UIAlertAction(title: "Cancel",
                                               style: .cancel,
            handler: {
                (action) -> Void in
                view.undoSwipe(onView: view.dualView!, sender: sender)
                                                
        })
        alertController.addAction(onFoot)
        alertController.addAction(nah)
        present(alertController, animated: true, completion: nil)
    }
    
    func locationManagerSetup() {
        if let appDelegate = appDelegate {
            if let manager = appDelegate.locationManager {
                manager.desiredAccuracy = kCLLocationAccuracyBest
                manager.distanceFilter = kCLDistanceFilterNone
                manager.startUpdatingLocation()
                if (CLLocationManager.headingAvailable()) {
                    manager.startUpdatingHeading()
                    manager.headingFilter = 5.0
                }
            }
        }
    }
    
    
    @IBAction func backButtonAction(_ sender: AnyObject) {
        //MARK: - TODO
    }
    @IBAction func addLocationAction(_ sender: AnyObject) {
        /*let width: CGFloat = self.view.bounds.size.width
        let height: CGFloat = (0.1)*self.view.bounds.size.height
        let frame: CGRect = CGRectMake(0, 0, width, height)
        collectionView = UICollectionView().then {
            $0.backgroundColor = UIColor.clearColor()
        }*/
        
    }
    
    // MARK: - OVERRIDDEN FUNCTIONS
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (self.isViewLoaded == true && self.view.window != nil) {
            if let motion = event {
                if motion.subtype == .motionShake {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        instantiateCustomView()
        distanceFromLocation()
        let place_id: String =
            results![numberOfShakesDetected]["place_id"] as! String
        Search.detailQuery(byPlaceID: place_id, returnData: returnPhoneNumber)
    }
}

//MARK: - LocationViewDataSource
extension DestinationViewController: LocationViewDataSource {
    
    func loadDataFor(_ view: LocationView) {
        if let data = results {
            if data.count > 0 {
                view.data = data[numberOfShakesDetected]
            }
        }
    }
    
    func requestImage(_ view: LocationView) {
        let ref =
            ((self.results?[self.numberOfShakesDetected]["photos"] as! NSArray)[0]
                as! NSDictionary)["photo_reference"] as! String
        Search.retrieveImageByReference(ref: ref, target: view.locationImageView)
    }
}

//MARK: - LocationViewDelegate
extension DestinationViewController: LocationViewDelegate {
    
    func initializeLongPress(_ view: LocationView, sender: UIGestureRecognizer) {
        if sender.state == .began {
            view.toggleState()
            if view.state == .pressed {
                view.addPreviewToSubview()
                view.layer.borderWidth = 0
            } else {
                view.layer.borderWidth = 5
            }
        }
    }
    
    func handleSwipeLeft(_ view: LocationView, sender: UISwipeGestureRecognizer) {
        if view.state == .pressed {
            let preview: UIView = view.viewWithTag(9)! //not nil if pressed
            let center_x: CGFloat = view.bounds.size.width/2
            let x_offset: CGFloat = view.bounds.size.width/6
            let y_offset: CGFloat = view.bounds.size.height/8
            let max_offset: CGPoint =
                CGPoint(x: center_x-x_offset, y: view.bounds.size.height/2-y_offset)
            if preview.center != max_offset {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear,
                                           animations: {
                                            preview.center.x -= x_offset
                                            preview.center.y -= y_offset
                    }, completion: {
                        completed in
                        if completed && preview.center.x != center_x {
                            UIView.animate(withDuration: 0.5, animations: {
                                view.dualView!.lhs!.backgroundColor = self.blue
                                view.dualView!.lhs_icon!.image = UIImage(named: "Marker")
                                }, completion: {
                                    _ in
                                    self.navigationAlert(onView: view, sender: sender)
                            })
                        } else if completed && preview.center.x == center_x {
                            UIView.animate(withDuration: 0.5, animations: {
                                view.dualView!.rhs!.backgroundColor = DualView.BGColor
                                view.dualView!.rhs_icon!.image =
                                    UIImage(named: "PhoneFilled-100")
                            })
                        }
                })
            }
        }
    }
    
    func handleSwipeRight(_ view: LocationView, sender: UISwipeGestureRecognizer) {
        if view.state == .pressed {
            let preview: UIView = view.viewWithTag(9)! //not nil if pressed
            let center_x: CGFloat = view.bounds.size.width/2
            let x_offset: CGFloat = view.bounds.size.width/6
            let y_offset: CGFloat = view.bounds.size.height/8
            let maxOffset: CGPoint =
                CGPoint(x: center_x+x_offset, y: view.bounds.size.height/2+y_offset)
            if preview.center != maxOffset {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear,
                                           animations: {
                                            preview.center.x += x_offset
                                            preview.center.y += y_offset
                    }, completion: {
                        completed in
                        if completed && preview.center.x != center_x {
                            UIView.animate(withDuration: 0.5, animations: {
                                view.dualView!.rhs!.backgroundColor = self.green
                                view.dualView!.rhs_icon!.image = UIImage(named: "Phone")
                                }, completion: {
                                    _ in
                                    self.callAlert(onView: view, sender: sender)
                            })
                        } else if completed && preview.center.x == center_x {
                            UIView.animate(withDuration: 0.5, animations: {
                                view.dualView!.lhs!.backgroundColor = DualView.BGColor
                                view.dualView!.lhs_icon!.image =
                                    UIImage(named: "MarkerFilled-100")
                            })
                        }
                })
                
            }
        }
    }

    
}



