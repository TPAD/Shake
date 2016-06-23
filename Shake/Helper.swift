//
//  Helper.swift
//  Shake
//
//  Created by Tony Padilla on 5/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {

    func horizontalShakeAnimation() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue =
            NSValue(CGPoint: CGPointMake(self.center.x - 5, self.center.y))
        animation.toValue =
            NSValue(CGPoint: CGPointMake(self.center.x + 5, self.center.y))
        animation.delegate = self
        
        self.layer.addAnimation(animation, forKey: "position")
    }
    
    func rotationAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = CGFloat(M_PI*(-0.05))
        animation.toValue = CGFloat(M_PI*(0.05))
        animation.autoreverses = true
        animation.repeatCount = 7
        animation.duration = 0.075
        
        self.layer.addAnimation(animation, forKey: nil)
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let layer: CAShapeLayer = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath(roundedRect: self.bounds,
        byRoundingCorners: corners, cornerRadii: CGSizeMake(radius, radius))
        layer.path = path.CGPath
        self.layer.mask = layer
        self.clipsToBounds = true
        self.layoutIfNeeded()
    }
    
    func roundView() {
        let white: UIColor =
            UIColor(red:255/255.0, green:255/255.0, blue:255/255.0, alpha:0.7)
        self.layer.cornerRadius = self.frame.height/2
        self.layer.borderWidth = 3
        self.layer.masksToBounds = false
        self.layer.borderColor = white.CGColor
        self.clipsToBounds = true
    }
    
    func offlineViewAppear() {
        let viewWidth = self.frame.width
        let viewHeight = 0.075*self.frame.height
        let view_y = self.frame.height - viewHeight
        let viewFrame: CGRect = CGRectMake(0, view_y, viewWidth, viewHeight)
        let view = UIView(frame: viewFrame)
        view.backgroundColor = UIColor.whiteColor()
        view.tag = 1
        
        let label = UILabel(frame: CGRectMake(0, viewFrame.height/4, 0, 0))
        
        self.addSubview(view)
        view.addSubview(label)
        label.text = "You are offline. Connection is required"
        label.textColor = UIColor.redColor()
        label.numberOfLines = 0
        label.lineBreakMode = .ByWordWrapping
        label.textAlignment = .Center
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
    
    func distanceInMilesFromLocation(location: CLLocation) -> Double {
        let distanceMeters = self.distanceFromLocation(location)
        return distanceMeters*0.00062137
    }
}

public extension String {
    
    func contains(string: String) -> Bool {
        let this: String = self.lowercaseString
        let that: String = string.lowercaseString
        
        if let _ = this.rangeOfString(that, options: .BackwardsSearch) {
            return true
        }
        
        return false
    }
    
    func numberFormattedForCall() -> String {
        let charactersToReplace: [String] = ["(", ")", " ", "-"]
        var filteredNum: String = self
        for character in charactersToReplace {
            filteredNum = filteredNum.stringByReplacingOccurrencesOfString(
                character, withString: "")
        }
        return filteredNum
    }
}

class Helper: NSObject {
    
    static func navigateToSettingsViaAlert(host: UIViewController) {
        let title: String = "Shake requires user's location to operate."
        let message: String = "Please authorize the use of your location."
        let alertController = UIAlertController(title: title,
            message: message, preferredStyle: .Alert)
        
        let settingsAction = UIAlertAction(title: "OK", style: .Default) {
            _ -> Void in
            let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                dispatch_after(dispatch_time_t(0.2), dispatch_get_main_queue(), {
                    UIApplication.sharedApplication().openURL(url)
                })
            }
        }
        alertController.addAction(settingsAction)
        
        host.presentViewController(alertController, animated: true, completion: nil);
    }
    
    static func relaunchAppNotification(host: UIViewController) {
        let title: String = "Please relaunch the application"
        
        let alertController =
            UIAlertController(title: title, message: "", preferredStyle: .Alert)
        
        host.presentViewController(alertController, animated: true, completion: nil);
    }
    
}
