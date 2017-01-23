//
//  DestinationViewController.swift
//  Shake
//
//  Created by Tony Padilla on 5/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//
import Foundation
import UIKit
import CoreLocation

// TODO: - interacting with Location is buggy (gesture recognizer interference)

enum Redirect { case Call, Map, Web }
/*
 *  DestinationViewController is the detail view controller
 *  It displays a Location object, shows the user how far away the location is,
 *  and where the user is relative to the location.
 *  Information is displayed in the Location object and more details on
 *  the location can be requested by tapping the Location object.
 *  Slide the DetailView up or down to enter full-screen or dismiss respectively.
 *  DetailView can scroll if expanded in which case the user can drag down %40
 *  of the screen to dismiss.
 *
 */
class DestinationViewController: UIViewController,
                                 DualViewDelegate,
                                 DetailViewDelegate,
                                 LocationViewDelegate,
                                 ViewControllerDelegate
{
    //ViewControllerDelegate routine used to initalize values
    internal func transferDataFrom(viewController: ViewController) {
        self.results = viewController.results
        self.userCoords = viewController.userCoord
        self.locationNames = viewController.locationNames
    }
    var shakeNum: Int = 0                  // kept to iterate through results
    var userLocation: CLLocation?          // set at initialization time
    var locationNames: [String?]?          // kept to reference locations if needed
    var results: Array<[String:NSObject]>?        /* place query results (20) */
    var userCoords: CLLocationCoordinate2D? {
        didSet {
            if userCoords != nil {
                userLocation = CLLocation(latitude: userCoords!.latitude,
                                          longitude: userCoords!.longitude)
            }
        }
            
    }
    var resultDetail: Array<[String:NSObject]>?      /* detail query results (20) */
    var distanceLabel: UILabel?
    var addressLabel: UILabel?
    var compass: UIImageView?
    var locationView: Location?                      /* object displays location */
    var detailView: DetailView?                      /* displays details */
    var detailShouldDisplay: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.detailShouldDisplay {
                    self.initDetailView()
                    UIView.animate(withDuration: 0.5, animations: {
                        self.detailView!.frame.origin.y = self.view.frame.height -
                            self.detailView!.frame.height
                    })
                } else {
                    if self.detailView == nil { return }
                    UIView.animate(withDuration: 0.5, animations: {
                        self.detailView!.frame.origin.y += self.detailView!.frame.height
                        }, completion: {
                            (completed) in
                            if completed { self.detailView!.removeFromSuperview() }
                    })
                }
            }
        }
    }
    
    // compass initializer
    private func initCompass() {
        let cWidth: CGFloat = locationView!.frame.width + 50
        let cHeight: CGFloat = locationView!.frame.height + 50
        let cx: CGFloat = locationView!.frame.origin.x - 25
        let cy: CGFloat = locationView!.frame.origin.y - 25
        let cframe = CGRect(x: cx, y: cy, width: cWidth, height: cHeight)
        compass = UIImageView(frame: cframe)
        compass!.image = UIImage(named: "comp")
        view.insertSubview(compass!, belowSubview: locationView!)
    }
    
    // detail view initializer
    private func initDetailView() {
        let width: CGFloat = (0.9)*view.frame.width
        let height: CGFloat = (0.825)*view.frame.height
        let frame: CGRect = CGRect(x: 0, y: view.frame.height,
                                   width: width, height: height)
        detailView = DetailView(dframe: frame, svframe: view.frame,
                                open: locationView?.isOpen)
        detailView!.datasource = locationView!
        detailView!.delegate = self
        detailView!.center.x = view.frame.width/2
        detailView!.loadData()
        if let label = distanceLabel {
            self.view.insertSubview(detailView!, aboveSubview: label)
        }
       
    }
    
    // address and distance label initializer
    private func initDescriptionViews() {
        distanceLabel = UILabel().then {
            $0.text = "Distance"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 30.0)
            $0.textColor = UIColor.white
            $0.textAlignment = .center
            $0.sizeToFit()
            $0.adjustsFontSizeToFitWidth = true
            $0.center.x = view.frame.width/2
            $0.frame.origin.y = locationView!.by(withOffset: view.frame.height/15)
        }
        
        addressLabel = UILabel().then {
            $0.text = "Street"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 25.0)
            $0.textColor = UIColor.white
            $0.textAlignment = .center
            $0.sizeToFit()
            $0.frame.size.width = (0.8)*view.frame.width
            $0.center.x = view.frame.width/2
            $0.frame.origin.y = distanceLabel!.by(withOffset: view.frame.height/25)
        }
        addressLabel!.adjustsFontSizeToFitWidth = true
        view.addSubview(addressLabel!)
        view.addSubview(distanceLabel!)
    }
    
    /*
     *  initializes an alert controller giving user redirect oprions
     *  - parameter type: determines where user would like to redirect
     */
    private func initRedirectAlertController(type: Redirect) {
        switch type {
        case .Call:
            if let names = locationNames {
                let name = names[shakeNum]! as String
                let title: String = "Call \(name)?"
                if locationView?.phoneNumber == nil { return }
                let number = locationView!.phoneNumber
                let callAction: UIAlertAction =
                    AlertActions.goTo(which: type, with: number!)
                let actions: [UIAlertAction] = [callAction, AlertActions.cancel]
                Helper.initAlertContoller(title: title, message: "", host: self,
                                          actions: actions, style: .actionSheet,
                                          completion: nil)
            }
            break
        case .Map:
            let title: String = "Open Google Maps?"
            let address: String? = self.locationView!.address
            if address == nil { return }
            let navAction: UIAlertAction =
                AlertActions.goTo(which: type, with: address!)
            let actions: [UIAlertAction] = [navAction, AlertActions.cancel]
            Helper.initAlertContoller(title: title, message: "", host: self,
                                      actions: actions, style: .actionSheet,
                                      completion: nil)
            break
        case .Web:
            if let url = detailView?.website {
                let title: String = "Open \(url) in Safari?"
                let webAction: UIAlertAction =
                    AlertActions.goTo(which: type, with: url)
                let actions: [UIAlertAction] = [webAction, AlertActions.cancel]
                Helper.initAlertContoller(title: title, message: "", host: self,
                                          actions: actions, style: .actionSheet,
                                          completion: nil)
            }
            break
        }
    }
    
    // clears Location data so the object is reused instead of reinitialized
    private func clearObjectData() {
        locationView?.ratingView.backgroundColor = Colors.mediumFirebrick
        locationView?.name.textColor = Colors.mediumFirebrick
        locationView?.phoneNumber = nil
        locationView?.address = nil
        locationView?.reviews = nil
        locationView?.weeklyHours = nil
        locationView?.openPeriods = nil
        locationView?.types = nil
        locationView?.mainType = nil
        locationView?.website = nil
    }
    
    /*
     *  queries location details by making api request
     *  - parameter atIndex: index of results array to access for relevant info
     */
    private func retrieveJSON(atIndex: Int) {
        if appDelegate == nil { return }
        if let res = results {
            if let id = res[atIndex]["place_id"] as? String {
                let params: Parameters = ["placeid": "\(id)",
                    "key": "\(appDelegate!.getApiKey())"]
                let session = URLSession.shared
                var search = GoogleSearch(type: .DETAIL, parameters: params)
                search.makeRequest(session, handler: responseHandler)
            }
        }
    }
    
    /*
     *  response handler for response received from api call
     *  updates ui components with response details if successful
     *  presents alerts signaling errors otherwise
     *  - parameter data: JSON data in the form of bytes from response
     *
     */
    private func responseHandler(data: Data?) {
        if data != nil {
            DispatchQueue.main.sync {
                do {
                    let json = try
                        JSONSerialization.jsonObject(with: data!,
                                                     options: .mutableContainers)
                        as! NSDictionary
                    let status: String? = json["status"] as? String
                    if status != nil && status! == "OK" {
                        let result = json["result"] as? [String:NSObject]
                        if let location = self.locationView {
                            location.rawData = result
                        }
                        // initalize address and distance label on first call only
                        if self.distanceLabel == nil && self.addressLabel == nil {
                            self.initDescriptionViews()
                        }
                        self.distanceLabel?.text =
                            self.locationView?.distanceFromLocation(self.userLocation!)
                            ?? "Distance from Location"
                        self.addressLabel?.text = self.locationView?.address
                            ?? "Location Address"
                    }
                } catch {
                    Helper.jsonConversionError(self)
                }
            }
        } else {
            Helper.invalidResponseError(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // intialize locationView object
        let width: CGFloat = (0.85)*view.frame.width
        let y: CGFloat = (0.15)*self.view.bounds.height
        let frame = CGRect(x: 0, y: y, width: width, height: width)
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(toggleDetail(_:)))
        locationView = Location(frame: frame)
        // Load the first result of the query
        retrieveJSON(atIndex: shakeNum)
        locationView?.center.x = view.center.x
        locationView?.rawData = (resultDetail?.count != 0) ?
            resultDetail?[shakeNum]: nil
        locationView?.delegate = self
        view.addGestureRecognizer(tap)
        view.addSubview(locationView!)
        initDescriptionViews()
        // initialize compass and location manager
        initCompass()
        locationManagerSetup()
        let swipe = UISwipeGestureRecognizer(target: self,
                                             action: #selector(unwindFromDetailVC(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)
    }
    
    /* Detects shake */
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        // requires that the view is loaded
        if (self.isViewLoaded == true && self.view.window != nil) {
            if let motion = event {
                if motion.subtype == .motionShake {
                    // safely traverses the data array
                    if let res = self.results {
                        let max = res.count
                        shakeNum = (shakeNum < max - 1 || max != 0) ?
                            shakeNum + 1: 0
                    }
                    // update locationView
                    clearObjectData()
                    retrieveJSON(atIndex: shakeNum)
                    locationView?.requestViewUpdate()
                    distanceLabel?.text =
                        locationView?.distanceFromLocation(userLocation!)
                    addressLabel?.text =
                        locationView?.address
                    if let aD = appDelegate {
                        if let coords = locationView!.coordinates {
                            aD.dest =
                                CLLocationCoordinate2D(latitude: coords.0,
                                                       longitude: coords.1)
                        }
                    }
                    if locationView?.state == .pressed {
                        locationView?.longTap(nil)
                    }
                    self.detailShouldDisplay = false
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let VC: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
        if let destination = VC as? ViewController {
            destination.animateSplash = false
        }
    }
    
    // swipe gesture action for dismissing view controller  #SELECTOR
    func unwindFromDetailVC(_ sender: UISwipeGestureRecognizer) {
        if !detailShouldDisplay {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // manages the detail display #SELECTOR
    func toggleDetail(_ sender: UIGestureRecognizer) {
        if detailShouldDisplay == false {
            let bounds: CGRect = locationView!.frame
            let pointTapped: CGPoint = sender.location(in: view)
            if bounds.contains(pointTapped) {
                detailShouldDisplay = !detailShouldDisplay
            }
        }
    }
    
    // This tap only exists when user has long pressed location #SELECTOR
    func userHasTapped(_ sender: UIGestureRecognizer) {
        let bounds: CGRect = locationView!.frame
        let pointTapped: CGPoint = sender.location(in: view)
        if !bounds.contains(pointTapped) {
            locationView?.toggleState()
            view.removeGestureRecognizer(sender)
        }
    }
    
    // notifies location manager that usr needs location updates
    // also accessed from app delegate when user re-enters app
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
    
    // AppDelegate uses this method to update distance in real time
    func updateDistance(_ manager: CLLocationManager, destination: CLLocation) {
        DispatchQueue.main.async(execute: {
            if let location: CLLocation = manager.location {
                let destination: CLLocation = destination
                let distance = location.distanceInMilesFromLocation(destination)
                let dString: String = String(format: "%.2f", distance)
                self.distanceLabel!.text = "\(dString)mi"
            }
        })
    }
    
    // MARK: - LocationViewDelegate
    func longPressAction(_ view: Location, sender: UIGestureRecognizer?) {
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
        appDelegate?.locationManager.stopUpdatingHeading()
        appDelegate?.locationManager.stopUpdatingLocation()
    }
    
    // MARK: - DualViewDelegate
    func navigationAction() {
        initRedirectAlertController(type: .Map)
    }
    
    func callLocationAction() {
        initRedirectAlertController(type: .Call)
    }
    
    // MARK: - DetailViewDelegate
    func redirectToCall() {
        initRedirectAlertController(type: .Call)
    }
    
    func redirectToMaps() {
        initRedirectAlertController(type: .Map)
    }
    
    func redirectToWeb() {
        initRedirectAlertController(type: .Web)
    }
    
    func saveLocation() {
        //TODO: - implement this 
        print("save")
    }
    
    func remove(detailView: DetailView) {
        detailShouldDisplay = false
    }
}



