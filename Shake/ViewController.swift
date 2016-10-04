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
    @IBOutlet weak var location: UIImageView!
    
    weak fileprivate var appDelegate: AppDelegate? =
        UIApplication.shared.delegate as? AppDelegate
    var results: Array<NSDictionary>?
    var resultDetail: Array<NSDictionary>?
    var locationNames: [String?]?
    var readyToSegue: Bool = false
    var userCoord: CLLocationCoordinate2D?
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationName.text = "Convenience Store"
        NotificationCenter.default.addObserver(self, selector:
        #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)),
        name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector:
        #selector(ViewController.applicationWillEnterBackground(_:)),
        name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        setBackgroundImage()
        
        if let appDelegate = self.appDelegate {
            let status = appDelegate.status as CLAuthorizationStatus
            if status == .restricted || status == .denied {
                Helper.requestPermission(self)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !Reachability.isConnected() {
            self.view.offlineViewAppear()
        }
        initialLoadView()
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        super.motionBegan(motion, with: event)
        if (self.isViewLoaded == true && self.view.window != nil) {
            if let motion = event {
                if motion.subtype == .motionShake && readyToSegue {
                    UIView.animate(withDuration: 0.4, delay: 0.0, options:
                        .curveEaseOut, animations: {
                            self.locationName.alpha = 0
                        }, completion: { _ in
                            self.goToDetail(self)
                    })
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DestinationViewController {
            if let data = results {
                destination.userCoords = userCoord
                destination.results = data
                destination.locationNames = self.locationNames
                destination.resultDetail = self.resultDetail
            }
        }
    }

    func goToDetail(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "toDetail", sender: sender)
    }
    
    func setBackgroundImage() {
        let view: UIImageView = UIImageView(frame: self.view.frame)
        view.image = UIImage(named: "gas_station")
    
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //fill the view
        blurEffectView.frame = self.view.frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        self.view.insertSubview(view, at: 0)
    }
    
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
    
    func applicationWillEnterBackground(_ notification: Notification) {
        print("did enter background")
    }
    
    @IBAction func testSegue(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "toDetail", sender: self)
    }
    
    func parse(_ json: [NSDictionary]?) {
        if json == nil { Helper.connectionHandler(host: self) }
        let array: [String?]
        if let data = json {
            array = data.map({($0["name"] as? String)})
            self.results = data
            self.locationNames = array
        }
        if let appDelegate = appDelegate {
            if let manager = appDelegate.locationManager {
                if let location = manager.location {
                    self.userCoord = location.coordinate
                }
                manager.stopUpdatingLocation()
            }
        }
        resultDetail = Array(repeating: NSDictionary(),
                             count: results!.count)
        if !Reachability.isConnected() { return }
        // Think about the performance implications of doing this
        // Should not be too much overhead on 20 queries
        //
        for (i, _) in results!.enumerated() {
            let place_id  = results?[i]["place_id"] as? String
            if let id = place_id {
                Search.detailQuery(byPlaceID: id,
                                   atIndex: i,
                                   returnData: loadDetails)
            }
        }
        readyToSegue = true
        print("done")
    }
    
    // completion block for query
    // TODO: - results are appended to array as the asynchronous requests are
    // completed. This is undesired behavior. Results should append sequentially
    func loadDetails(_ details: NSDictionary?, _ index: Int?) {
        if let data = details {
            guard let result = data["result"] as? NSDictionary else {
                // TODO: - Handle this error
                return
            }
            resultDetail![index!] = result
        } else {
            //TODO: - handle this error
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
            $0.image = UIImage(named: "ShakeLogo")
        }
        
        if let appDelegate = self.appDelegate {
            if let manager = appDelegate.locationManager {
                
                if let location = manager.location {
                    let query: String = "convenience_store"
                    Search.GSearh(query, location: location, parser: self.parse,
                                  host: self)
                }
            }
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
            UIView.animate(withDuration: 0.80, delay: 0.05, options: UIViewAnimationOptions(), animations: {
                image.center.y -= (view.frame.height)
                }, completion: {
                    _ -> Void in
                    self.fadeOut(view)
            })
        });
    }
    
    func fadeOut(_ view: UIView) {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            view.alpha = 0
            
            }, completion: {
                _ -> Void in
                view.removeFromSuperview()
                
        })
        
    }
}










