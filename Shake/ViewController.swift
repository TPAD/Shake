//
//  ViewController.swift
//  Shake
//
//  Created by Tony Padilla on 5/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

/*
 *  ViewController corresponds to the initial view controller
 *  User can select a nearby location they would like to query
 *  After a response is retrieved from a call to Google Places API Web Service
 *
 */
class ViewController: UIViewController, TypePickerDelegate {
    
    
    @IBOutlet weak var desiredLocation: UILabel!
    var typePicker: TypePicker?
    var results: Array<NSDictionary>?
    var resultDetail: Array<NSDictionary>?
    var locationNames: [String?]?               /* investigate this (may not need)*/
    var readyToSegue: Bool = false
    var userCoord: CLLocationCoordinate2D?
    var qstring: String? 
    
    // MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(toggleTypes(_:)))
        tap.numberOfTapsRequired = 1
        desiredLocation.addGestureRecognizer(tap)
        desiredLocation.isUserInteractionEnabled = true

        
        if let appDelegate = appDelegate {
            let status = appDelegate.status as CLAuthorizationStatus
            if status == .restricted || status == .denied {
                Helper.requestPermission(self)
            }
        }
    }
    
    // Method overriden to display an animation before the view has loaded
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !Reachability.isConnected() {
            self.view.offlineViewAppear()
        }
        initialLoadView()
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
            if let data = results {
                destination.userCoords = userCoord
                destination.results = data
                destination.locationNames = self.locationNames
                destination.resultDetail = self.resultDetail
            }
        }
    }

    /* segue with button for testing purposes */
    func goToDetail(_ sender: AnyObject) {
        if readyToSegue {
            self.performSegue(withIdentifier: "toDetail", sender: sender)
        }
    }
    
    /* Allows the user to select the type of place they would like to query */
    func toggleTypes(_ sender: UITapGestureRecognizer) {
        if typePicker == nil {
            let height: CGFloat =
                desiredLocation.by(withOffset: 0) - view.by(withOffset: -40)
            typePicker = TypePicker().then {
                $0.frame.size.width = view.frame.width - 60
                $0.frame.size.height = height
                $0.frame.origin.y = desiredLocation.by(withOffset: 10)
                $0.center.x = view.frame.width/2
            }
            view.addSubview(typePicker!)
            typePicker!.delegate = self
            typePicker!.alpha = 0
            typePicker!.backgroundColor = UIColor.white
            UIView.animate(withDuration: 0.5, animations: {
                self.typePicker!.alpha = 1
            })
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.typePicker!.alpha = 0
                }, completion: {
                    (completed) in
                    if completed {
                       self.typePicker!.removeFromSuperview()
                        self.typePicker = nil
                    }
            })
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
        self.performSegue(withIdentifier: "toDetail", sender: self)
    }
    
    // grabs data from Google Search
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
        if !Reachability.isConnected() { return }
        readyToSegue = true
        print("done")
    }
    
    func runQuery(string: String) {
        if let appDelegate = appDelegate {
            if let manager = appDelegate.locationManager {
                if let location = manager.location {
                    Search.GSearh(string, location: location,
                                  parser: self.parse, host: self)
                }
            }
        }
    }
    
    /*  MARK:- TypePickerDelegate method */
    
    /*  lets the user know which location type they have chosen
     *  starts a new query once user selects a new location
     *
     */
    func setDesiredLocation(using: TypePicker) {
        let location = using.chosen
        if let result = location?.replacingOccurrences(of: "_", with: " ") {
            desiredLocation.text = result
            qstring = result
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
            $0.image = UIImage(named: "ShakeLogo")
        }
        
        runQuery(string: "convenience_store")
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
        UIView.animate(withDuration: 0.5, delay: 0,
                       options: UIViewAnimationOptions(), animations: {
            view.alpha = 0
            }, completion: {
            (completed) in
                if completed { view.removeFromSuperview() }
        })
        
    }
}









