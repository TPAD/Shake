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
    
    var distanceLabel: UILabel?
    weak private var appDelegate: AppDelegate? =
        UIApplication.shared.delegate as? AppDelegate
    let blue: UIColor =
        UIColor(red: 78/255.0, green:147/255.0, blue:222/255.0, alpha: 1.0)
    let green: UIColor =
        UIColor(red:70/255.0, green:179/255.0, blue:173/255.0, alpha: 1.0)
    var locationNames: [String?]?
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
    var shakeNum: Int = 0
    var locationToSearch: String = "gas station"
    var descriptionHolder: UIView?
    var resultDetail: Array<NSDictionary>?
    var locationView: Location?
    
    // MARK: - OVERRIDDEN FUNCTIONS
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (self.isViewLoaded == true && self.view.window != nil) {
            if let motion = event {
                if motion.subtype == .motionShake {
                    if let max = self.results?.count {
                        if shakeNum < max-1 {
                            shakeNum += 1
                        } else {
                            shakeNum = 0
                        }
                    }
                    locationView?.requestViewUpdate()
                    distanceLabel?.text =
                        locationView?.distanceFromLocation(userLocation!)
                    if locationView?.state == .pressed {
                        locationView?.longTap(nil)
                    }
                }
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let width: CGFloat = (0.85)*view.frame.width
        let y: CGFloat = (0.15)*self.view.bounds.height
        let frame = CGRect(x: 0, y: y, width: width, height: width)
        locationView = Location(frame: frame)
        locationView?.center.x = view.center.x
        locationView?.rawData = resultDetail?[shakeNum]
        locationView?.delegate = self
        view.addSubview(locationView!)
        //TODO: - finish implementing this
        descriptionHolder = UIView().then {
            let x1: CGFloat = (0.05)*self.view.bounds.width
            let y1: CGFloat =
                (0.15)*self.view.bounds.height + locationView!.bounds.height
            let height1: CGFloat = (0.4)*locationView!.bounds.height
            let width: CGFloat = (0.9)*self.view.bounds.width
            let textFrame: CGRect = CGRect(x: x1, y: y1, width: width, height: height1)
            $0.frame = textFrame
            $0.backgroundColor = UIColor.clear
        }
        view.addSubview(descriptionHolder!)
        initDescriptionViews()
        distanceLabel?.text = locationView?.distanceFromLocation(userLocation!)
    }
    
    private func initDescriptionViews() {
        distanceLabel = UILabel().then {
            $0.text = "Distance"
            $0.font = UIFont(name: "Avenir", size: 25.0)
            $0.textColor = UIColor.white
            $0.textAlignment = .center
            $0.sizeToFit()
            $0.adjustsFontSizeToFitWidth = true
            $0.center.x = descriptionHolder!.bounds.width/2
            $0.frame.origin.y = 1*descriptionHolder!.bounds.height/2
        }
        self.descriptionHolder!.addSubview(distanceLabel!)
    }
    
    // APP Delegate uses this method to update distance in real time
    // TODO: - implement this
    func updateDistance(_ manager: CLLocationManager, destination: CLLocation) {
        Helper.GlobalMainQueue.async(execute: {
            if let location: CLLocation = manager.location {
                let destination: CLLocation = destination
                let distance = location.distanceInMilesFromLocation(destination)
                let dString: String = String(format: "%.2f", distance)
                self.distanceLabel!.text = "\(dString)mi"
            }
        })
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
}

//MARK: - not explicitly delegated
extension DestinationViewController {
    
    func callAction(_ view: Location, _ sender: UISwipeGestureRecognizer) {
        locationView?.longTap(nil)
        if let num = locationView?.phoneNumber {
            if let url = URL(string: "tel://\(num.numberFormattedForCall())") {
                UIApplication.shared.open(url, completionHandler: nil)
            }
        } else {
            view.undoSwipe(onView: view.dualView!, sender: sender)
            // TODO: alert of sorts
            print("Action can't be completed RN")
        }
    }
    
    func callAlert(onView view: Location, sender: UISwipeGestureRecognizer) {
        if let names = locationNames {
            let name = names[shakeNum]! as String
            let title: String = "Call \(name)?"
            let alertController: UIAlertController
                = UIAlertController(title: title, message: "",
                                    preferredStyle: .actionSheet)
            let yes = UIAlertAction(title: "Ok", style: .default, handler: {
                (action) -> Void in
                self.callAction(view, sender)
            })
            let nah = UIAlertAction(title: "No", style: .cancel, handler: {
                (action) -> Void in
                view.undoSwipe(onView: view.dualView!, sender: sender)
            })
            alertController.addAction(yes)
            alertController.addAction(nah)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func navigationAlert(onView view: Location, sender: UISwipeGestureRecognizer) {
        let title: String = "Navigation Mode"
        let alertController: UIAlertController =
            UIAlertController(title: title, message: "",
                              preferredStyle: .actionSheet)
        
        let onFoot: UIAlertAction =
            UIAlertAction(title: "On Foot", style: .default,
            handler: { (action) -> Void in
                self.locationManagerSetup()
        })
        let nah: UIAlertAction =
            UIAlertAction(title: "Cancel", style: .cancel,
            handler: { (action) -> Void in
                view.undoSwipe(onView: view.dualView!, sender: sender)
        })
        alertController.addAction(onFoot)
        alertController.addAction(nah)
        present(alertController, animated: true, completion: nil)
    }
}

//MARK: - LocationViewDelegate
extension DestinationViewController: LocationViewDelegate {
    
    func initializeLongPress(_ view: Location, sender: UIGestureRecognizer?) {
        if sender == nil || sender?.state == .began {
            view.toggleState()
            if view.state == .pressed {
                view.addPreviewToSubview()
            }
        }
    }
    
    func handleSwipeLeft(_ view: Location, sender: UISwipeGestureRecognizer) {
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
    
    func handleSwipeRight(_ view: Location, sender: UISwipeGestureRecognizer) {
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
    
    func updateView(_ view: Location) {
        if let res = resultDetail {
            if res.count > 0 {
                view.rawData = res[shakeNum]
            }
        }
    }

} 

