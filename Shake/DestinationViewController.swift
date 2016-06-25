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
import Cosmos
import Alamofire
import AlamofireImage

class DestinationViewController: UIViewController {
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    let blue: UIColor =
        UIColor(red: 78/255.0, green:147/255.0, blue:222/255.0, alpha: 1.0)
    let green: UIColor =
        UIColor(red:70/255.0, green:179/255.0, blue:173/255.0, alpha: 1.0)
    
    var locationView: LocationView?
    
    var locationNames: [String?]?
    var address: String?
    var userLocation: CLLocation?
   
    var results: Array<NSDictionary>?
    var iconCount: Int = 0
    var numberOfShakesDetected: Int = 0
    var locationToSearch: String = "gas station"
    var locationPhoneNumber: String?
    
    func instantiateCustomView() {
        let y: CGFloat = (0.15)*self.view.frame.height
        let x: CGFloat = (0.05)*self.view.frame.width
        let width: CGFloat = (0.9)*self.view.frame.width
        
        let frame: CGRect = CGRectMake(x, y, width, width)
        locationView = LocationView(frame: frame)
        locationView!.dataSource = self
        locationView!.delegate = self
        locationView!.loadData()
        self.view.addSubview(locationView!)
    }
    
    // MARK: - Setup
    
    func distanceFromLocation() {
        if let places = results {
            if let geometry = places[numberOfShakesDetected]["geometry"] {
                if let location = geometry["location"] as? NSMutableDictionary {
                    let lat = location["lat"] as! Double
                    let lng = location["lng"] as! Double
                    let locationA = CLLocation(latitude: lat, longitude: lng)
                    if let locationB = self.userLocation {
                        let distance = locationB.distanceInMilesFromLocation(locationA)
                        let dString: String = String(format: "%.2f", distance)
                        self.distanceLabel.text = "\(dString)mi"
                    }
                    
                }
            }
        }
    }
    
    
    //MARK: - Animations
    func exitLocationView() {
        UIView.animateWithDuration(0.45, delay: 0.0, options: .CurveEaseOut, animations: {
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
        UIView.animateWithDuration(0.45, delay: 0.05, options: .CurveEaseIn, animations: {
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
            if let url = NSURL(string: "tel://\(num)") {
                UIApplication.sharedApplication().openURL(url)
            }
        } else {
            // TODO: alert of sorts
            print("Action can't be completed RN")
        }
    }
    
    func callAlert() {
        if let names = locationNames {
            let name = names[numberOfShakesDetected]! as String
            let title: String = "Call \(name)?"
            let alertController = UIAlertController(title: title, message: "", preferredStyle: .ActionSheet)
            let yes = UIAlertAction(title: "Ok", style: .Default, handler: {
                (action) -> Void in
                self.callAction()
            })
            let nah = UIAlertAction(title: "No", style: .Cancel, handler: nil)
            alertController.addAction(yes)
            alertController.addAction(nah)
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - OVERRIDDEN FUNCTIONS
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (self.isViewLoaded() == true && self.view.window != nil) {
            if let motion = event {
                if motion.subtype == .MotionShake {
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
    
    func loadDataFor(view: LocationView) {
        if let data = results {
            if data.count > 0 {
                view.data = data[numberOfShakesDetected]
            }
        }
    }
    
    func requestImage(view: LocationView) {
        if let names = locationNames {
            Search.imageQuery(locationToSearch, atIndex: numberOfShakesDetected,
                              list: names, imageView: view.locationImageView)
        }
    }
}

//MARK: - LocationViewDelegate
extension DestinationViewController: LocationViewDelegate {
    
    func initializeLongPress(view: LocationView, sender: UIGestureRecognizer) {
        if sender.state == .Began {
            //view.addSubview(dView!)
            view.toggleState()
            if view.state == .Pressed {
                view.addPreviewToSubview()
                view.layer.borderWidth = 0
            } else {
                view.layer.borderWidth = 5
            }
        }
    }
    
    func handleSwipeLeft(view: LocationView, sender: UISwipeGestureRecognizer) {
        if view.state == .Pressed {
            let preview: UIView = view.viewWithTag(9)! //not nil if pressed
            let center_x: CGFloat = view.bounds.size.width/2
            let x_offset: CGFloat = view.bounds.size.width/6
            let y_offset: CGFloat = view.bounds.size.height/8
            let max_offset: CGPoint =
                CGPointMake(center_x-x_offset, view.bounds.size.height/2-y_offset)
            if preview.center != max_offset {
                UIView.animateWithDuration(0.25, delay: 0, options: .CurveLinear,
                                           animations: {
                                            preview.center.x -= x_offset
                                            preview.center.y -= y_offset
                    }, completion: {
                        completed in
                        if completed && preview.center.x != center_x {
                            UIView.animateWithDuration(0.5, animations: {
                                view.dualView!.lhs!.backgroundColor = self.blue
                                view.dualView!.lhs_icon!.image = UIImage(named: "Marker")
                                }, completion: {
                                    _ in
                                    print("navigate")
                            })
                        } else if completed && preview.center.x == center_x {
                            UIView.animateWithDuration(0.5, animations: {
                                view.dualView!.rhs!.backgroundColor = DualView.BGColor
                                view.dualView!.rhs_icon!.image =
                                    UIImage(named: "PhoneFilled-100")
                            })
                        }
                })
            }
        }
    }
    
    func handleSwipeRight(view: LocationView, sender: UISwipeGestureRecognizer) {
        if view.state == .Pressed {
            let preview: UIView = view.viewWithTag(9)! //not nil if pressed
            let center_x: CGFloat = view.bounds.size.width/2
            let x_offset: CGFloat = view.bounds.size.width/6
            let y_offset: CGFloat = view.bounds.size.height/8
            let maxOffset: CGPoint =
                CGPointMake(center_x+x_offset, view.bounds.size.height/2+y_offset)
            if preview.center != maxOffset {
                UIView.animateWithDuration(0.25, delay: 0, options: .CurveLinear,
                                           animations: {
                                            preview.center.x += x_offset
                                            preview.center.y += y_offset
                    }, completion: {
                        completed in
                        if completed && preview.center.x != center_x {
                            UIView.animateWithDuration(0.5, animations: {
                                view.dualView!.rhs!.backgroundColor = self.green
                                view.dualView!.rhs_icon!.image = UIImage(named: "Phone")
                                }, completion: {
                                    _ in
                                    self.callAlert()
                            })
                        } else if completed && preview.center.x == center_x {
                            UIView.animateWithDuration(0.5, animations: {
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



