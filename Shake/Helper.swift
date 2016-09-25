//
//  Helper.swift
//  Shake
//
//  Created by Tony Padilla on 5/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

public struct Helper {
    
    static var GlobalMainQueue: DispatchQueue {
        return DispatchQueue.main
    }
    
    static func requestPermission(_ host: UIViewController) {
        let title: String = "Shake requires user's location to operate."
        let message: String = "Please authorize the use of your location."
        let alertController = UIAlertController(title: title,
                                                message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "OK", style: .default) {
            _ -> Void in
            let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: UInt64(0.5)), execute: {
                    UIApplication.shared.open(url, completionHandler: nil)
                })
            }
        }
        alertController.addAction(settingsAction)
        
        host.present(alertController, animated: true, completion: nil);
    }
    
    static func relaunchAppAlert(_ host: UIViewController) {
        let title: String = "Please relaunch the application"
        
        let alertController =
            UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        host.present(alertController, animated: true, completion: nil);
    }
    
    struct Colors {
        static var mediumSeaweed: UIColor {
            return UIColor(red:60/255.0, green:179/255.0,
                           blue:113/255.0, alpha: 0.8)
        }
        
        static var mediumFirebrick: UIColor {
            return UIColor(red:205/255.0, green:35/255.0,
                           blue:35/255.0, alpha:0.8)
        }
    }
}

//MARK: - EXTENSIONS ON UIKit CLASSES
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
    
    func roundView() {
        let white: UIColor =
            UIColor(red:255/255.0, green:255/255.0, blue:255/255.0, alpha:0.7)
        self.layer.cornerRadius = self.frame.height/2
        self.layer.borderWidth = 3
        self.layer.masksToBounds = false
        self.layer.borderColor = white.cgColor
        self.clipsToBounds = true
    }
    
    func offlineViewAppear() {
        let viewWidth = self.frame.width
        let viewHeight = 0.075*self.frame.height
        let view_y = self.frame.height - viewHeight
        let viewFrame: CGRect = CGRect(x: 0, y: view_y, width: viewWidth, height: viewHeight)
        let view = UIView(frame: viewFrame)
        view.backgroundColor = UIColor.white
        view.tag = 1
        
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
            if subview.tag == 1 {
                subview.removeFromSuperview()
            }
        }
    }
}

public extension CLLocation {
    
    func distanceInMilesFromLocation(_ location: CLLocation) -> Double {
        let distanceMeters = self.distance(from: location)
        return distanceMeters*0.00062137
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
    
    func numberFormattedForCall() -> String {
        let charactersToReplace: [String] = ["(", ")", " ", "-"]
        var filteredNum: String = self
        for character in charactersToReplace {
            filteredNum = filteredNum.replacingOccurrences(
                    of: character, with: "")
        }
        return filteredNum
    }
}

public extension UILabel {
    
    func requiredHeight() -> CGFloat {
        let frame: CGRect = CGRect(x: 0, y: 0, width: self.frame.width,  height: CGFloat.greatestFiniteMagnitude)
        let new: UILabel = UILabel(frame: frame)
        new.numberOfLines = 0
        new.lineBreakMode = .byWordWrapping
        new.font = self.font
        new.text = self.text
        new.sizeToFit()
        
        return new.frame.height
    }
}

//MARK: - Syntactical Sugar

public protocol Then {}

/*extension Then where Self: Any {
    
    public func then(@noescape _ block: inout (Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}*/

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
