//
//  Helper.swift
//  Shake
//
//  Created by Tony Padilla on 5/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//
import Foundation
import UIKit
import CoreLocation
import GoogleMaps

/*
 *  Helper file containing various class extensions and helper structs
 *
 */
public let weekdays: [String] = ["Monday:", "Tuesday:", "Wednesday:",
                       "Thursday:", "Friday:", "Saturday:", "Sunday:"]

// global appDelegate reference is a little suspect
internal var appDelegate: AppDelegate =
    UIApplication.shared.delegate as! AppDelegate

/*
 *  MARK: - struct LocationTypes
 *  Used by TypePicker object
 *
 */
public struct LocationTypes {
    static var fun: [String] {
        return ["movie_theater", "night_club", "bar",
                "liquor_store", "museum", "park"]
    }
    
    static var miscellaneous: [String] {
        return ["church", "hair_care", "library", "bus_station",
                "clothing_store", "department_store"]
    }
    
    static var need: [String] {
        return ["hospital", "pharmacy", "doctor", "dentist",
                "car_repair", "gas_station"]
    }
    
    static var other: [String] {
        return ["bank", "atm", "cafe", "restaurant",
                "convenience_store", "post_office"]
    }
}

/*
 *  MARK: - struct Colors
 *  contains the colors used throughout the project
 *
 */
public struct Colors {
    
    // green for open location (used with white background bar in Location)
    static var mediumSeaweed: UIColor {
        return UIColor(red:60/255.0, green:179/255.0,
                       blue:113/255.0, alpha: 0.8)
    }
    
    static var seaweed: UIColor {
        return UIColor(red:60/255.0, green:179/255.0,
                       blue:113/255.0, alpha: 1.0)
    }
    
    // red for closed location (used with white background bar in Location)
    static var mediumFirebrick: UIColor {
        return UIColor(red:205/255.0, green:35/255.0,
                       blue:35/255.0, alpha:0.8)
    }
    
    // Jack's blue
    static var new: UIColor {
        return UIColor(red:0/255.0, green:96/255.0,
                       blue:192/255.0, alpha:1)
    }
    
    // Tony's blue
    static var blue: UIColor {
        return UIColor(red: 78/255.0, green:147/255.0,
                       blue:222/255.0, alpha: 1.0)
    }
    
    //used for phone button in DualView
    static var green: UIColor {
        return   UIColor(red:70/255.0, green:179/255.0,
                         blue:173/255.0, alpha: 1.0)
    }
    
    // Google blue (background color for ViewController)
    static var gBlue: UIColor {
        return   UIColor(red:72/255.0, green:139/255.0,
                         blue:240/255.0, alpha: 1.0)
    }
    
    // background color for DestinationViewController
    static var bgRed: UIColor {
        return UIColor(red: 194/255.0, green: 70/255.0,
                       blue: 68/255.0, alpha: 1.0)
    }
}

/*
 *  MARK: - struct AlertActions
 *  contains the UIAlertActions used throughout the project
 *
 */
public struct AlertActions {
    
    // declaration for an object user can use to dismiss a UIAlertController
    static var cancel: UIAlertAction = {
        return UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    }()
    
    static var ok: UIAlertAction = {
        return UIAlertAction(title: "Ok", style: .cancel, handler: nil)
    }()
    
    /*  declaration for an object user can use to navigate to their settings
     *  from a UIAlertController
     */
    static var goToSettings: UIAlertAction = {
        let settingsAction =
            UIAlertAction(title: "OK", style: .default,
                          handler: openSettingsIfPossible)
        return settingsAction
    }()
    
    /*  returns an object the user can use to navigate out of app to
     *  call a location, for a map to a location (Google Maps),
     *  or to open Safari browser with location's website
     */
    static func goTo(which: Redirect, with: String) -> UIAlertAction {
        let action = UIAlertAction(title: "Ok", style: .default, handler: {
            _ -> Void in
            switch which {
            case .Call:
                Helper.dial(number: with)
                break
            case .Map:
                Helper.redirectToGoogleMaps(destination: with)
                break
            case .Web:
                Helper.redirectToSafari(website: with)
                break
            }
        })
        return action
    }
    
    // allows the user to navigate to their settings
    private static func openSettingsIfPossible(action: (UIAlertAction)?) {
        let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        if let url = settingsUrl {
            // not sure why this is necessary (crashed otherwise)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(
                uptimeNanoseconds: UInt64(0.5)), execute: {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, completionHandler: nil)
                    } else {
                        //MARK: - TODO Fallback on earlier versions
                    }
            })
        }
    }
    
}

public struct Helper {
    
    static func jsonConversionError(_ host: UIViewController) {
        let message: String = "error converting JSON"
        Helper.initAlertContoller(title: "", message: message, host: host,
                                  actions: [AlertActions.ok], style: .alert,
                                  completion: nil)
    }
    
    static func invalidResponseError(_ host: UIViewController) {
        let message: String = "error parsing response or url"
        Helper.initAlertContoller(title: "", message: message, host: host,
                                  actions: [AlertActions.ok], style: .alert,
                                  completion: nil)
    }
    
    static func alertOnBadResponse(status: String, host: UIViewController) {
        let title: String = "Request Failed"
        var message: String?
        if status == "ZERO_RESULTS" {
            message = "search returned 0 results"
        } else if status == "OVER_QUERY_LIMIT"  {
            message = "search quota exceeded"
        } else if status == "REQUEST_DENIED" {
            message = "request denied, possible invalid key"
        } else if status == "INVALID_REQUEST" {
            message = "required query parameter wrong or missing"
        } else {
            message = status
        }
        if message == nil { message = " " }
        Helper.initAlertContoller(title: title, message: message!, host: host,
                                  actions: [AlertActions.ok], style: .alert,
                                  completion: nil)
    }
    
    static func initAlertContoller(title: String, message: String,
                                   host: UIViewController,
                                   actions: [UIAlertAction],
                                   style: UIAlertControllerStyle,
                                   completion: (() -> Void)?) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: style)
        for action in actions {
            alertController.addAction(action)
        }
        host.present(alertController, animated: true, completion: completion)
    }
    
    // requests the user for permission to use their location
    static func requestPermission(_ host: UIViewController) {
        let title: String = "Shake requires user's location to operate."
        let message: String = "Please authorize the use of your location."
        let actions: [UIAlertAction] = [AlertActions.goToSettings]
        initAlertContoller(title: title, message: message, host: host,
                           actions: actions, style: .actionSheet,
                           completion: nil)
    }
    
    // notifies the user that they must relaunch the app to continue
    static func relaunchAppAlert(_ host: UIViewController) {
        let title: String = "Please relaunch the application"
        let alertController =
            UIAlertController(title: title, message: "", preferredStyle: .alert)
        host.present(alertController, animated: true, completion: nil);
    }
    
    // used to display a message when us is offline
    static func connectionHandler(host: UIViewController) {
        if !Reachability.isConnected() {
            let view: UIView = UIView().then {
                $0.frame.size.width = host.view.bounds.width
                $0.frame.size.height = (0.1)*host.view.bounds.height
                $0.frame.origin.y = (0.9)*host.view.bounds.height
                $0.backgroundColor = UIColor.red
            }
            host.view.addSubview(view)
            let label: UILabel = UILabel().then {
                $0.textColor = UIColor.white
                $0.text = "No Internet connection detected"
                $0.font = UIFont(name: "SanFranciscoText-Light", size: 16.0)
                $0.sizeToFit()
                $0.center.x = view.center.x
                $0.center.y = view.center.y
            }
            view.addSubview(label)
        }
    }
    
    // returns the topmost view controller or nil
    static func topMostViewController() -> UIViewController? {
        let topController: UIViewController? =
            UIApplication.shared.keyWindow?.rootViewController
        if let top = topController {
            let presentedController: UIViewController? = top.presentedViewController
            if let top_most = presentedController {
                return top_most
            }
        }
        return nil
    }
    
    // Returns the day of the week (range: 1-7)
    static func dayOfWeek() -> Int {
        let date = NSDate()
        let calendar: NSCalendar = NSCalendar.current as NSCalendar
        let components: NSDateComponents =
            calendar.components(.weekday, from: date as Date)
                as NSDateComponents
        return components.weekday
    }
    
    /* navigate out of app to google maps */
    static func redirectToGoogleMaps(destination: String) {
        if appDelegate.locationManager?.location == nil { return }
        let location = appDelegate.locationManager!.location
        let coord = location?.coordinate
        if coord == nil { return }
        GMSGeocoder().reverseGeocodeCoordinate(coord!) {
            (response, error) in
            if error == nil {
                let gmaps = URL(string: "comgooglemaps://")
                if response?.firstResult() == nil { return }
                let address = response!.firstResult()
                let lines = address!.lines! as [String]
                var start = lines.joined(separator: ", ")
                start = start.replacingOccurrences(of: " ", with: "+")
                let daddr = destination.replacingOccurrences(of: " ", with: "+")
                let format = "comgooglemaps://??saddr=\(start)" +
                             "&daddr=\(daddr)&directionsmode=travel"
                let url = URL(string: format)
                if (UIApplication.shared.canOpenURL(gmaps!)) {
                    if url == nil { return }
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url!)
                    } else {
                        // Fallback on earlier versions
                    }
                } else {
                    //TODO: - handle this error
                    print("Can't use comgooglemaps://");
                }
            }
        }
    }
    
    static func dial(number: String) {
        if let url = URL(string: "tel://\(number.formattedForCall())") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, completionHandler: nil)
            } else {
                // fallback on earlier version
            }
        } else {
            //MARK: - TODO raise error
        }
    }
    
    static func redirectToSafari(website: String) {
        if let url = URL(string: website) {
            UIApplication.shared.open(url, options: ["":""],
                                      completionHandler: nil)
        } else {
            //MARK: - TODO raise error
        }
    }
}

//MARK: - EXTENSIONS on UIKit classes
public extension UIView {
    
    func rotationAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = CGFloat(M_PI*(-0.05))
        animation.toValue = CGFloat(M_PI*(0.05))
        animation.autoreverses = true
        animation.repeatCount = 7
        animation.duration = 0.075
        
        self.layer.add(animation, forKey: nil)
    }
    
    func roundView(borderWidth: CGFloat) {
        let white: UIColor =
            UIColor(red:255/255.0, green:255/255.0, blue:255/255.0, alpha:0.7)
        layer.cornerRadius = self.frame.height/2
        layer.borderWidth = borderWidth
        layer.masksToBounds = false
        layer.borderColor = white.cgColor
        clipsToBounds = true
    }
    
    func offlineViewAppear() {
        // sucks but ensures only one kind of these views is present
        self.offlineViewDisappear()
        let viewWidth = self.frame.width
        let viewHeight = 0.075*self.frame.height
        let view_y = self.frame.height - viewHeight
        let viewFrame: CGRect = CGRect(x: 0, y: view_y, width: viewWidth, height: viewHeight)
        let view = OfflineView(frame: viewFrame)
        view.backgroundColor = UIColor.white
        
        let label = UILabel(frame: CGRect(x: 0, y: viewFrame.height/4, width: 0, height: 0))
        
        self.addSubview(view)
        view.addSubview(label)
        label.text = "You are offline. Connection is required"
        label.textColor = UIColor.red
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.sizeToFit()
        label.center.x = view.center.x
    }
    
    func offlineViewDisappear() {
        for subview in self.subviews {
            if subview.isKind(of: OfflineView.self) {
                subview.removeFromSuperview()
            }
        }
    }
    
    func pushTransition(duration:CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionPush
        animation.subtype = kCATransitionFromLeft
        animation.duration = duration
        self.layer.add(animation, forKey: kCATransitionPush)
    }
    
    /* get y at the base of a view frame with an offset */
    func by(withOffset: CGFloat) -> CGFloat {
        let originy = self.frame.origin.y
        let height = self.frame.height
        return originy + height + withOffset
    }
    
    /* get x at the base of a view frame with an offset */
    func bx(withOffset: CGFloat) -> CGFloat {
        let originx = self.frame.origin.x
        let width = self.frame.width
        return originx + width + withOffset
    }
    
    /* check if a view is beneath another */
    func frameIsBelow(view: UIView) -> Bool {
        return self.frame.origin.y >= view.by(withOffset: 0) &&
            view != self
    }
}


public extension CLLocation {
    // converts distance in meters to miles 
    func distanceInMilesFromLocation(_ location: CLLocation) -> Double {
        let distanceMeters = self.distance(from: location)
        return distanceMeters*0.00062137
    }
}

public extension CLLocationCoordinate2D {
    // calculates angle between self and other location (bearing)
    func angleTo(destination: CLLocationCoordinate2D) -> Double {
        var x: Double = 0; var y: Double = 0
        var deg: Double = 0; var delta_long: Double
        // using the equation for bearing calculation
        delta_long = destination.longitude - self.longitude
        y = sin(delta_long) * cos(destination.latitude)
        x = cos(self.latitude) * sin(destination.latitude) -
            sin(self.latitude) * cos(destination.latitude)*cos(delta_long)
        // need result in radians
        deg = atan2(y, x).radiansToDegrees as! Double
        // necessary adjustments for negative angles
        return (deg < 0) ? -deg: 360-deg
    }
}

public extension String {
    
    func contains(_ string: String) -> Bool {
        let this: String = self.lowercased()
        let that: String = string.lowercased()
        if let _ = this.range(of: that, options: .backwards) {
            return true
        }
        
        return false
    }
    
    // appropriate formatting for a phone number
    func formattedForCall() -> String {
        let charactersToReplace: [String] = ["(", ")", " ", "-"]
        var filteredNum: String = self
        for character in charactersToReplace {
            filteredNum = filteredNum.replacingOccurrences(
                of: character, with: "")
        }
        return filteredNum
    }
    
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
}



// adjusts height
public extension UILabel {

    func requiredHeight() -> CGFloat {
        let frame: CGRect = CGRect(x: 0, y: 0, width: self.frame.width,
                                   height: CGFloat.greatestFiniteMagnitude)
        let new: UILabel = UILabel(frame: frame)
        new.numberOfLines = 0
        new.lineBreakMode = .byWordWrapping
        new.font = self.font
        new.text = self.text
        new.sizeToFit()
        
        return new.frame.height
    }
}

//MARK: - Syntactical sugar for initialization
// just keeps everything in one place
public protocol Then {}

extension Then where Self: AnyObject {
    
    public func then(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}

extension NSObject: Then{}

//MARK: - Float to Double Conversion
protocol DoubleConvertible {
    init(_ double: Double)
    var double: Double { get }
}
extension Double : DoubleConvertible { var double: Double { return self         } }
extension Float  : DoubleConvertible { var double: Double { return Double(self) } }
extension CGFloat: DoubleConvertible { var double: Double { return Double(self) } }

extension DoubleConvertible {
    var degreesToRadians: DoubleConvertible {
        return Self(double * M_PI / 180)
    }
    var radiansToDegrees: DoubleConvertible {
        return Self(double * 180 / M_PI)
    }
}

//MARK: - offline view
//makes the view easier to identify and consequently easier to remove
class OfflineView: UIView { }

extension ReviewsContainerView {
    func sumOfSubviewHeights() -> CGFloat {
        var result: CGFloat = 0.0
        for view in self.subviews {
            if view.isKind(of: ReviewView.self) {
                result += view.frame.height
            }
        }
        return result
    }
}
