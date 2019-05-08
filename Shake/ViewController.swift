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
    
    @IBOutlet weak var shakeIcon: UIImageView!
    weak var delegate: ViewControllerDelegate?

    var results = Array<[String:NSObject]>()
    var locationNames: [String?]?
    var userCoord: CLLocationCoordinate2D?
    var qstring: String?
    var animateSplash: Bool = true
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        shakeIcon.rotationAnimation()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !Reachability.isConnected() {
            self.view.offlineViewAppear()
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
    private func goToDetail(_ sender: AnyObject) {
        DispatchQueue.main.async {
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
        } else {
            DispatchQueue.main.async {
                Helper.alertOnBadResponse(status: "location is nil", host: self)
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
                    for location in res {
                        self.results.append(location)
                    }
                    self.locationNames = res.map({($0["name"] as? String)})
                    let manager = appDelegate.locationManager
                    if let location = manager.location {
                        self.userCoord = location.coordinate
                    }
                    manager.stopUpdatingLocation()
                    //if !Reachability.isConnected() { return }
                    print("done")
                    self.goToDetail(self)
                } else if status != nil {
                    DispatchQueue.main.sync {
                        Helper
                            .alertOnBadResponse(status: "\(status!)", host: self)
                    }
                }
            } catch {
                Helper.jsonConversionError(self)
            }
        } else {
            Helper.invalidResponseError(self)
        }
    }
}
