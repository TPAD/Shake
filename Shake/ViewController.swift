//
//  ViewController.swift
//  Shake
//
//  Created by Tony Padilla on 5/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

protocol ViewControllerDelegate: class {
    func transferDataFrom(viewController: ViewController)
}

/*
 *  ViewController corresponds to the initial view controller
 *  User can select a nearby location they would like to query
 *  a response is retrieved from a call to Google Places API Web Service
 *
 */

class ViewController: UIViewController, TypePickerDelegate {
    
    @IBOutlet weak var desiredLocation: UILabel!
    
    weak var delegate: ViewControllerDelegate?
    
    var typePicker: TypePicker?
    var results: Array<[String:NSObject]>?
    var locationNames: [String?]?
    var readyToSegue: Bool = false
    var userCoord: CLLocationCoordinate2D?
    var qstring: String?
    
    var animateSplash: Bool = true

    var exButton: UIButton?
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        desiredLocation.isUserInteractionEnabled = true
        
        if let appDelegate = appDelegate {
            let status = appDelegate.status as CLAuthorizationStatus
            if status == .restricted || status == .denied {
                Helper.requestPermission(self)
            }
        }
        runQuery(string: "convenience_store")
        initExpandButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !Reachability.isConnected() {
            self.view.offlineViewAppear()
        }
        if animateSplash {
            initialLoadView()
        }
    }
    
    // detects shake motion in real time
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        super.motionBegan(motion, with: event)
        // make sure shake is only detected when the view is loaded
        if (self.isViewLoaded == true && self.view.window != nil) {
            if let motion = event {
                // make sure data necessary is retrieved before segue
                if motion.subtype == .motionShake && readyToSegue {
                    self.goToDetail(self)
                }
            }
        }
    }
    
    /* sends necessary data to destination controller  */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DestinationViewController {
            delegate = destination
            delegate?.transferDataFrom(viewController: self)
        }
    }
    
    func initExpandButton() {
        let width: CGFloat = (0.15)*view.frame.width
        let height: CGFloat = (0.6)*width
        exButton = UIButton().then {
            $0.frame.size.width = width
            $0.frame.size.height = height
            $0.center.x = view.center.x
            $0.frame.origin.y = view.frame.height - height
            $0.alpha = 0.8
            $0.setImage(UIImage(named: "collapse-white"), for: .normal)
            $0.addTarget(self, action: #selector(showLocationOptions(_:)),
                         for: .touchUpInside)
        }
        view.addSubview(exButton!)
    }
    
    /* Allows the user to select the type of place they would like to query */
    func showLocationOptions(_ sender: AnyObject) {
        if typePicker == nil {
            let height: CGFloat =
                desiredLocation.by(withOffset: 0) - view.by(withOffset: -60)
            typePicker = TypePicker().then {
                $0.frame.size.width = view.frame.width - 60
                $0.frame.size.height = height
                $0.center.x = view.frame.width/2
                $0.frame.origin.y = view.by(withOffset: 0)
                $0.alpha = 1
            }
            view.addSubview(typePicker!)
            typePicker!.delegate = self
            typePicker!.backgroundColor = UIColor.white
            DispatchQueue.main.async {
                let th = self.typePicker!.frame.height
                UIView.animate(withDuration: 0.5, animations: {
                    self.typePicker!.frame.origin.y -= th
                    self.exButton!.frame.origin.y -= th
                    self.exButton!.setImage(UIImage(named: "expand-white"),
                                            for: .normal)
                })
            }
        } else {
            DispatchQueue.main.async {
                let th = self.typePicker!.frame.height
                UIView.animate(withDuration: 0.5, animations: {
                    self.typePicker!.frame.origin.y += th
                    self.exButton!.frame.origin.y += th
                    self.exButton!.setImage(UIImage(named: "collapse-white"),
                                            for: .normal)
                }, completion: {
                    _ in
                    self.typePicker!.removeFromSuperview()
                    self.typePicker = nil
                })
            }
        }
    }

    /* segue with button for testing purposes */
    func goToDetail(_ sender: AnyObject) {
        if readyToSegue {
            self.performSegue(withIdentifier: "toDetail", sender: sender)
        }
    }
    
    // helps resolve internet connectivity issues when user leaves and returns to the app */
    func applicationWillEnterForeground(_ notification: Notification) {
        if let appDelegate = appDelegate {
            let status = appDelegate.status
            if status == .restricted || status == .denied {
                Helper.relaunchAppAlert(self)
            }
        }
        if !Reachability.isConnected() {
            self.view.offlineViewDisappear()
            self.view.offlineViewAppear()
        } else {
            self.view.offlineViewDisappear()
        }
    }
    
    // segue performed with the test button
    @IBAction func testSegue(_ sender: AnyObject) {
        if readyToSegue {
            self.performSegue(withIdentifier: "toDetail", sender: self)
        }
    }
    
    func runQuery(string: String) {
        if let appDelegate = appDelegate {
            if let manager = appDelegate.locationManager {
                if let location = manager.location {
                    let session = URLSession.shared
                    let coord = location.coordinate
                    let lat: String = "\(coord.latitude)"
                    let lng: String = "\(coord.longitude)"
                    let params: Parameters = ["location":"\(lat),\(lng)",
                                              "rankby":"distance",
                                              "type":"restaurant",
                                              "key":"\(appDelegate.getApiKey())"]
                    var search = GoogleSearch(type: .NEARBY, parameters: params)
                    search.makeRequest(session, handler: responseHandler)
                }
            }
        }
    }
    
    /*
     *  retrieves JSON data on a successful http response and parses location names.
     *  handles failed http responses otherwise
     */
    func responseHandler(data: Data?) {
        if data != nil {
            do {
                let json = try
                    JSONSerialization.jsonObject(with: data!,
                                                 options: .mutableContainers)
                    as! NSDictionary
                let status: String? = json["status"] as? String
                if status != nil && status! == "OK" {
                    let res = json["results"]! as! Array<[String: NSObject]>
                    self.results = res
                    self.locationNames = res.map({($0["name"] as? String)})
                    if let appDelegate = appDelegate {
                        if let manager = appDelegate.locationManager {
                            if let location = manager.location {
                                self.userCoord = location.coordinate
                            }
                            manager.stopUpdatingLocation()
                        }
                    }
                    if !Reachability.isConnected() { return }
                    readyToSegue = true
                    print("done")
                } else {
                    Helper.alertOnBadResponse(status: "\(status)", host: self)
                }
            } catch {
                Helper.jsonConversionError(self)
            }
        } else {
            Helper.invalidResponseError(self)
        }
    }
    
    /*  MARK:- TypePickerDelegate method */
    
    /*  lets the user know which location type they have chosen
     *  starts a new query once user selects a new location
     */
    func setDesiredLocation(using: TypePicker) {
        let location = using.chosen
        if let result = location?.replacingOccurrences(of: "_", with: " ") {
            desiredLocation.text = result
        }
        if let query = location {
            runQuery(string: query)
        }
    }
}

//MARK: - Initial Load Animation

extension ViewController {
    
    func initialLoadView() {
        let mainView = UIView(frame: self.view.frame).then {
            $0.backgroundColor = UIColor.white
        }
        let logo = UIImageView().then {
            $0.frame.size.width =  0.35*(mainView.frame.width)
            $0.frame.size.height = 0.35*(mainView.frame.width)
            $0.center = mainView.center
            $0.image = UIImage(named: "Shake-icon-inverse")
        }
        mainView.addSubview(logo)
        self.view.addSubview(mainView)
        //runQuery(string: "convenience_store")
        initialLoadAnimation(mainView, image: logo)
    }
    
    func initialLoadAnimation(_ view: UIView, image: UIImageView) {
        image.rotationAnimation()
        
        let delayInSeconds: Int64  = 800000000
        
        let popTime: DispatchTime = DispatchTime.now() + Double(delayInSeconds) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
            UIView.animate(withDuration: 0.80, delay: 0.05, options: UIViewAnimationOptions(), animations: {
                image.center.y -= (view.frame.height)
                }, completion: {
                    _ -> Void in
                    self.fadeOut(view)
            })
        });
    }
    
    func fadeOut(_ view: UIView) {
        UIView.animate(withDuration: 0.5, delay: 0,
                       options: UIViewAnimationOptions(), animations: {
            view.alpha = 0
            }, completion: {
            (completed) in
                if completed { view.removeFromSuperview() }
        })
        
    }
}









