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

class ViewController: UIViewController {
    
    @IBOutlet weak var desiredLocation: UILabel!
    
    weak var delegate: ViewControllerDelegate?
    
    var results = Array<[String:NSObject]>()
    var locationNames: [String?]?
    var readyToSegue: Bool = false
    var userCoord: CLLocationCoordinate2D?
    var qstring: String?
    
    var animateSplash: Bool = true
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        desiredLocation.isUserInteractionEnabled = true
        
        let status = appDelegate.status as CLAuthorizationStatus
        if status == .restricted || status == .denied {
            Helper.requestPermission(self)
        }
        runQuery()
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
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
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

    /* segue with button for testing purposes */
    func goToDetail(_ sender: AnyObject) {
        if readyToSegue {
            self.performSegue(withIdentifier: "toDetail", sender: sender)
        }
    }
    
    // helps resolve internet connectivity issues when user leaves and returns to the app */
    func applicationWillEnterForeground(_ notification: Notification) {
        let status = appDelegate.status
        if status == .restricted || status == .denied {
            Helper.relaunchAppAlert(self)
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
    
    func runQuery() {
        if let location = appDelegate.locationManager.location {
            let session = URLSession.shared
            let coord = location.coordinate
            let lat: String = "\(coord.latitude)"
            let lng: String = "\(coord.longitude)"
            let gasParams: Parameters = ["location":"\(lat),\(lng)",
                "name":"CoinFlip",
                "rankby":"distance",
                "type":"atm",
                "key":"\(appDelegate.getApiKey())"]
            
            var searchGas = GoogleSearch(type: .NEARBY, parameters: gasParams)
            searchGas.makeRequest(session, handler: responseHandler)
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
                    print(res)
                    for location in res {
                        self.results.append(location)
                    }
                    self.locationNames = res.map({($0["name"] as? String)})
                    if let manager = appDelegate.locationManager {
                        if let location = manager.location {
                            self.userCoord = location.coordinate
                        }
                        manager.stopUpdatingLocation()
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
        initialLoadAnimation(mainView, image: logo)
    }
    
    func initialLoadAnimation(_ view: UIView, image: UIImageView) {
        image.rotationAnimation()
        
        let delayInSeconds: Int64  = 800000000
        
        let popTime: DispatchTime = DispatchTime.now() + Double(delayInSeconds) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
            UIView.animate(withDuration: 0.80, delay: 0.05, options: UIView.AnimationOptions(), animations: {
                image.center.y -= (view.frame.height)
                }, completion: {
                    _ -> Void in
                    self.fadeOut(view)
            })
        });
    }
    
    func fadeOut(_ view: UIView) {
        UIView.animate(withDuration: 0.5, delay: 0,
                       options: UIView.AnimationOptions(), animations: {
            view.alpha = 0
            }, completion: {
            (completed) in
                if completed { view.removeFromSuperview() }
        })
        
    }
}









