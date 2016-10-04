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
    var addressLabel: UILabel?
    weak var appDelegate: AppDelegate? =
        UIApplication.shared.delegate as? AppDelegate
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
    var compass: UIImageView?
    var detailView: DetailView?
    var detailIsDisplayed: Bool = false
    
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
                    addressLabel?.text =
                        locationView?.address
                    if let aD = self.appDelegate {
                        aD.dest =
                            CLLocationCoordinate2D(latitude: self.locationView!
                                                    .coordinates!.0!,
                                                   longitude: self.locationView!
                                                    .coordinates!.1!)
                    }
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
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(toggleDetail(_:)))
        locationView = Location(frame: frame)
        locationView?.center.x = view.center.x
        locationView?.rawData = resultDetail?[shakeNum]
        locationView?.delegate = self
        view.addGestureRecognizer(tap)
        view.addSubview(locationView!)
        initDetailView()
        initCompass()
        locationManagerSetup()
        if let aD = self.appDelegate {
            aD.dest =
                CLLocationCoordinate2D(latitude: self.locationView!
                                       .coordinates!.0!,
                                       longitude: self.locationView!
                                       .coordinates!.1!)
        }
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
        addressLabel?.text = locationView?.address
    }
    
    func toggleDetail(_ sender: UIGestureRecognizer) {
        detailIsDisplayed = !detailIsDisplayed
        let bounds: CGRect = locationView!.frame
        let pointTapped: CGPoint = sender.location(in: view)
        if bounds.contains(pointTapped) {
            if detailIsDisplayed {
                print("should not display")
                UIView.animate(withDuration: 0.5, animations: {
                    self.detailView!.frame.origin.y += self.detailView!.frame.height
                })
                self.detailView!.removeFromSuperview()
            } else {
                print("should dispaly")
                UIView.animate(withDuration: 0.5, animations: {
                    self.detailView!.frame.origin.y -= self.detailView!.frame.height
                })
            }
        }
    }
    
    // This tap only exists when user has long pressed location
    func userHasTapped(_ sender: UIGestureRecognizer) {
        let bounds: CGRect = locationView!.frame
        let pointTapped: CGPoint = sender.location(in: view)
        if !bounds.contains(pointTapped) {
            locationView?.toggleState()
            view.removeGestureRecognizer(sender)
        }
    }
    
    private func initDetailView() {
        let width: CGFloat = (0.9)*self.view.frame.width
        let height: CGFloat = (0.7)*self.view.frame.height
        let frame: CGRect = CGRect(x: 0, y: self.view.frame.height,
                                   width: width, height: height)
        detailView = DetailView(frame: frame)
        detailView!.center.x = self.view.frame.width/2
        self.view.insertSubview(detailView!, aboveSubview: locationView!)
    }
    
    private func initDescriptionViews() {
        distanceLabel = UILabel().then {
            $0.text = "Distance"
            $0.font = UIFont(name: "Avenir", size: 30.0)
            $0.textColor = UIColor.white
            $0.textAlignment = .center
            $0.sizeToFit()
            $0.adjustsFontSizeToFitWidth = true
            $0.center.x = descriptionHolder!.bounds.width/2
            $0.frame.origin.y = (0.25)*descriptionHolder!.bounds.height
        }
        
        addressLabel = UILabel().then {
            $0.text = "Street"
            $0.font = UIFont(name: "Avenir", size: 25.0)
            $0.textColor = UIColor.white
            $0.textAlignment = .center
            $0.sizeToFit()
            $0.frame.size.width = (0.8)*descriptionHolder!.frame.width
            $0.center.x = descriptionHolder!.bounds.width/2
            $0.frame.origin.y = (0.25)*descriptionHolder!.bounds.height +
                (1.5)*distanceLabel!.bounds.height
        }
        addressLabel!.adjustsFontSizeToFitWidth = true
        descriptionHolder!.addSubview(addressLabel!)
        descriptionHolder!.addSubview(distanceLabel!)
    }
    
    func initCompass() {
        let cWidth: CGFloat = locationView!.frame.width + 50
        let cHeight: CGFloat = locationView!.frame.height + 50
        let cx: CGFloat = locationView!.frame.origin.x - 25
        let cy: CGFloat = locationView!.frame.origin.y - 25
        let cframe = CGRect(x: cx, y: cy, width: cWidth, height: cHeight)
        compass = UIImageView(frame: cframe)
        compass!.image = UIImage(named: "comp")
        view.insertSubview(compass!, belowSubview: locationView!)
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
                manager.distanceFilter = 10
                manager.startUpdatingLocation()
                if (CLLocationManager.headingAvailable()) {
                    manager.startUpdatingHeading()
                    manager.headingFilter = 20.0
                }
            }
        }
    }
    
    func callAction() {
        if let num = locationView?.phoneNumber {
            if let url = URL(string: "tel://\(num.numberFormattedForCall())") {
                UIApplication.shared.open(url, completionHandler: nil)
            }
        } else {
            //view.undoSwipe(onView: view.dualView!, sender: sender)
            // TODO: alert of sorts
            print("Action can't be completed RN")
        }
    }
}


//MARK: - LocationViewDelegate
extension DestinationViewController: LocationViewDelegate {
    
    func initializeLongPress(_ view: Location, sender: UIGestureRecognizer?) {
        view.dualView = DualView(frame: view.bounds)
        view.dualView!.tag = 10
        view.dualView!.alpha = 0
        view.dualView!.delegate = self
        if sender == nil || sender?.state == .began {
            view.toggleState()
            if view.state == .pressed {
                let tap =
                    UITapGestureRecognizer(target: self,
                                           action: #selector(self.userHasTapped(_:)))
                self.view.addGestureRecognizer(tap)
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
    
    func haltLocationUpdates() {
        print("location stoppped updating")
        appDelegate?.locationManager.stopUpdatingHeading()
        appDelegate?.locationManager.stopUpdatingLocation()
    }
}

extension DestinationViewController: DualViewDelegate {
    
    func navigationAction(_ sender: UIGestureRecognizer, onView: DualView) {
        let title: String = "Navigation Mode"
        let alertController: UIAlertController =
            UIAlertController(title: title, message: "",
                              preferredStyle: .actionSheet)
        
        let onFoot: UIAlertAction =
            UIAlertAction(
                title: "On Foot", style: .default,
                handler: { (action) -> Void in
                // TODO: Implement this
            })
        let nah: UIAlertAction =
            UIAlertAction(title: "Cancel", style: .cancel,
                          handler: { (action) -> Void in
            })
        alertController.addAction(onFoot)
        alertController.addAction(nah)
        present(alertController, animated: true, completion: nil)

    }
    
    func callLocationAction(_ sender: UIGestureRecognizer, onView: DualView) {
        if let names = locationNames {
            let name = names[shakeNum]! as String
            let title: String = "Call \(name)?"
            let alertController: UIAlertController
                = UIAlertController(title: title, message: "",
                                    preferredStyle: .actionSheet)
            let yes = UIAlertAction(title: "Ok", style: .default, handler: {
                (action) -> Void in
                self.callAction()
            })
            let nah = UIAlertAction(title: "No", style: .cancel, handler: {
                (action) -> Void in
            })
            alertController.addAction(yes)
            alertController.addAction(nah)
            present(alertController, animated: true, completion: nil)
        }
    }
}

