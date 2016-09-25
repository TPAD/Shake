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
    var locationNames: [String?]?
    var address: String?
    var readyToSegue: Bool = false
    var userCoord: CLLocationCoordinate2D? {
        didSet{
            print("location set");
        }
    }
    
    // MARK: - Override Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationName.text = "Gas Station"
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
        
        /*let width: CGFloat = self.view.frame.width
        let frame: CGRect = CGRectMake(0, 0, width, width/5)
        let starView = RatingView(frame: frame)
        starView.rating = 0.0
        self.view.addSubview(starView)*/
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !Reachability.isConnected() {
            self.view.offlineViewAppear()
            print("Not connected")
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
                destination.address = self.address
                destination.userCoords = userCoord
                destination.results = data
                destination.locationNames = self.locationNames
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
        print("did enter foreground")
        if let appDelegate = appDelegate {
            let status = appDelegate.status
            if status == .restricted || status == .denied {
                Helper.relaunchAppAlert(self)
            }
        }
        if !Reachability.isConnected() {
            self.view.offlineViewDisappear()
            self.view.offlineViewAppear()
            print("not connected")
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
        let array: [String?]
        if let data = json {
            array = data.map({($0["name"] as? String)})
            self.results = data
            self.locationNames = array
        }
        //UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if let appDelegate = appDelegate {
            if let address = appDelegate.address, let manager = appDelegate.locationManager {
                self.address = address
                if let location = manager.location {
                    self.userCoord = location.coordinate
                }
            }
        }
        readyToSegue = true
        print("done")
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
        
        let progress = UIProgressView().then {
            $0.frame.size.width = mainView.frame.width
            $0.frame.origin.y = mainView.frame.height - 2*$0.frame.height
            $0.trackTintColor = UIColor.black
            $0.progressTintColor = UIColor.blue
            let transform = CGAffineTransform(scaleX: 1.0, y: 3.0);
            $0.transform = transform;
        }
        
        if let appDelegate = self.appDelegate {
            if let manager = appDelegate.locationManager {
                
                if let location = manager.location {
                    let query: String = "gas_station"
                    Search.GSearh(query, location: location, parser: self.parse)
                }
            }
        }

        mainView.addSubview(logo)
        mainView.addSubview(progress)
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










