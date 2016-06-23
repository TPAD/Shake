//
//  LocationView.swift
//  Shake
//
//  Created by Tony Padilla on 6/11/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

import UIKit
import Cosmos

//MARK: - DATASOURCE
protocol LocationViewDataSource: class {
    func loadDataFor(view: LocationView)
    func requestImage(view: LocationView)
}

protocol LocationViewDelegate: class {
    func initializeLongPress(view: LocationView, sender: UIGestureRecognizer)
    func handleSwipeRight(view: LocationView, sender: UISwipeGestureRecognizer)
    func handleSwipeLeft(view: LocationView, sender: UISwipeGestureRecognizer)
}

class LocationView: UIView {
    weak var iconLeft: UIImageView?
    weak var iconRight: UIImageView?
    weak var iconCenter: UIImageView?
    var dualView: DualView?
    
    var data: NSDictionary? {
        didSet {
            if data != nil {
                setLocationName()
                setRating()
                clearIcons()
                drawIcons()
                starView.backgroundColor = locationIsOpenNow() ?
                //medium seaweed
                UIColor(red:60/255.0, green:179/255.0, blue:113/255.0, alpha: 0.8):
                //medium firebrick
                UIColor(red:205/255.0, green:35/255.0, blue:35/255.0, alpha:0.8)
            }
        }
    }
    
    weak var dataSource: LocationViewDataSource?
    weak var delegate: LocationViewDelegate?
    
    var locationImageView: UIImageView = UIImageView()
    var nameView: UIView = UIView()
    var starView: UIView = UIView()
    var locationName: UILabel = UILabel()
    var rating: CosmosView = CosmosView()
    var numberOfIcons: Int = 0
    let white: UIColor =
        UIColor(red:255/255.0, green:255/255.0, blue:255/255.0, alpha:0.7)
    
    var longPress: UILongPressGestureRecognizer?
    var leftSwipe: UISwipeGestureRecognizer?
    var rightSwipe: UISwipeGestureRecognizer?
    
    enum State {
        case Default
        case Pressed
    }
    
    var state: State = .Default {
        didSet {
            if let v = self.viewWithTag(9) {
                UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseOut,
                animations: { v.alpha = 0 }, completion: {
                    _ in
                    v.removeFromSuperview()
                })
            }
            switch state {
            case .Default:
                for subview in subviews {
                    if subview.isKindOfClass(DualView) {
                        UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseOut,
                        animations: { subview.alpha = 0 }, completion: {
                            _ in
                            subview.removeFromSuperview()
                        })
                    }
                }
            case .Pressed:
                dualView = DualView(frame: self.bounds)
                dualView!.alpha = 0
                addSubview(dualView!)
                UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseIn,
                animations: { self.dualView!.alpha = 1 }, completion: { _ in })
            }
        }
    }
    
    func toggleState() {
        state = (state == .Default) ? .Pressed:.Default
    }
    
    private func setLocationName() {
        if let name = data!["name"] as? String {
            locationName.text = name
            locationName.font = UIFont(name: "PingFangHK-Regular", size: 30)
            locationName.textColor = locationIsOpenNow() ?
                //medium seaweed
                UIColor(red:60/255.0, green:179/255.0, blue:113/255.0, alpha: 0.8):
                //medium firebrick
                UIColor(red:205/255.0, green:35/255.0, blue:35/255.0, alpha:0.8)
            locationName.adjustsFontSizeToFitWidth = true
        }
    }
    
    private func setRating() {
        self.rating.settings.fillMode = .Precise
        self.rating.userInteractionEnabled = false
        if let stars = data!["rating"] {
            self.rating.rating = stars as! Double
        }
    }
    
    private func nameLabelSetup() {
        let width: CGFloat = 0.75*(nameView.frame.width)
        let height:CGFloat = 0.3*(nameView.frame.height)
        let frame = CGRectMake(0, 0, width, height)
        locationName.frame = frame
        locationName.center.x = nameView.center.x
        locationName.textAlignment = .Center
        nameView.addSubview(locationName)
    }
    
    private func nameViewSetup() {
        let y: CGFloat = 0.7*(self.frame.height)
        let width: CGFloat = self.frame.width
        let height: CGFloat = 0.3*(self.frame.height)
        let frame: CGRect =
            CGRectMake(0, y, width, height)
        nameView.frame = frame
        nameView.backgroundColor = white
        self.addSubview(nameView)
    }
    
    private func mainImageViewSetup() {
        let y: CGFloat = (0.12)*self.frame.height
        let width: CGFloat = self.frame.width
        let height: CGFloat = (0.58)*self.frame.height
        let frame: CGRect = CGRectMake(0, y, width, height)
        locationImageView.frame = frame
        locationImageView.backgroundColor = UIColor.blackColor()
        self.addSubview(locationImageView)
    }
    
    private func setupStarsView() {
        let height: CGFloat = 0.12*(self.frame.height)
        let width: CGFloat = self.frame.width
        let frame: CGRect = CGRectMake(0, 0, width, height)
        starView.frame = frame
        starView.backgroundColor = white
        self.addSubview(starView)
    }
    
    private func ratingViewSetup() {
        let width: CGFloat = (0.45)*starView.frame.width
        let height: CGFloat = (0.3)*starView.frame.height
        let frame: CGRect = CGRectMake(0, 0, width, height)
        rating.frame = frame
        rating.center = starView.center
        rating.settings.starSize = 24
        starView.addSubview(rating)
    }
    
    private func locationHasCarRepair() -> Bool {
        if let types = data!["types"] as? [String] {
            if types.contains("car_repair") { return true }
        }
        return false
    }
    
    private func locationHasATM() -> Bool {
        if let types = data!["types"] as? [String] {
            if types.contains("atm") { return true }
        }
        return false
    }
    
    private func locationIsConvenienceStore() -> Bool {
        if let types = data!["types"] as? [String] {
            if types.contains("conveneince_store") { return true }
        }
        return false
    }
    
    private func locationIsOpenNow() -> Bool {
        if let hours = data!["opening_hours"] as? NSMutableDictionary {
            if let currentlyOpen = hours["open_now"] as? Int {
                return (currentlyOpen == 0) ? false:true
            }
        }
        return false
    }
    
    private func setNumberOfIcons(locationHas:(repair: Bool, ATM: Bool, store: Bool) -> Void) {
        let carRepair: Bool = locationHasCarRepair()
        let atm: Bool = locationHasATM()
        let isStore: Bool = locationIsConvenienceStore()
        if carRepair && atm && isStore {
            numberOfIcons = 3
        } else if carRepair && atm || atm && isStore || carRepair && isStore {
            numberOfIcons = 2
        } else if carRepair || atm || isStore {
            numberOfIcons = 1
        } else {
            numberOfIcons = 0
        }
        locationHas(repair: carRepair, ATM: atm, store: isStore)
    }
    
    private func drawIcons() {
        setNumberOfIcons({
            (repair, ATM, store) -> Void in
            let width: CGFloat = (0.085)*self.nameView.frame.width
            let frame: CGRect = CGRectMake(0, 0, width, width)
            let imageView1 = UIImageView(frame: frame)
            let imageView2 = UIImageView(frame: frame)
            let imageView3 = UIImageView(frame:frame)
            let x: CGFloat = (0.5)*self.nameView.frame.width
            let y: CGFloat = (0.5)*(self.nameView.frame.height + width)
          
            if self.numberOfIcons == 3 {
                self.iconLeft = imageView1
                self.iconCenter = imageView2
                self.iconRight = imageView3
                let center: CGPoint = CGPointMake(x, y)
                let center_left: CGPoint = CGPointMake(x-1.5*width, y)
                let center_right: CGPoint = CGPointMake(x+1.5*width, y)
                self.iconCenter!.center = center
                self.iconLeft!.center = center_left
                self.iconRight!.center = center_right
                self.iconLeft!.image = UIImage(named: "car_repair-71")
                self.iconCenter!.image = UIImage(named: "atm-71")
                self.iconRight!.image = UIImage(named: "shopping-71")
                self.nameView.addSubview(self.iconCenter!)
                self.nameView.addSubview(self.iconRight!)
                self.nameView.addSubview(self.iconLeft!)
                
            } else if self.numberOfIcons == 2 {
                self.iconLeft = imageView1
                self.iconRight = imageView2
                let center_left: CGPoint = CGPointMake(x-2*width/3, y)
                let center_right: CGPoint = CGPointMake(x+2*width/3, y)
                self.iconLeft!.center = center_left
                self.iconRight!.center = center_right

                if repair && ATM {
                    self.iconLeft!.image = UIImage(named: "car_repair-71")
                    self.iconRight!.image = UIImage(named: "atm-71")
                } else if repair && store {
                    self.iconLeft!.image = UIImage(named: "car_repair-71")
                    self.iconRight!.image = UIImage(named: "shopping-71")
                } else {
                    self.iconLeft!.image = UIImage(named: "shopping-71")
                    self.iconRight!.image = UIImage(named: "atm-71")
                }
                self.nameView.addSubview(self.iconRight!)
                self.nameView.addSubview(self.iconLeft!)
                
            } else if self.numberOfIcons == 1 {
                self.iconCenter = imageView1
                let center: CGPoint = CGPointMake(x, y)
                self.iconCenter!.center = center

                if repair && !ATM && !store {
                    self.iconCenter!.image = UIImage(named: "car_repair-71")}
                else if ATM && !repair && !store {
                    self.iconCenter!.image = UIImage(named: "atm-71")}
                else if store && !ATM && !repair {
                    self.iconCenter!.image = UIImage(named: "shopping-71")}
                self.nameView.addSubview(self.iconCenter!)
            }
        })
    }
    
    func longTap(sender: UIGestureRecognizer) {
        delegate?.initializeLongPress(self, sender: sender)
        
    }
    
    func addPreviewToSubview() {
        
        let widgetWidth: CGFloat = (0.35)*self.frame.width
        let frame: CGRect = CGRectMake(0, 0, widgetWidth, widgetWidth)
        let smallView: UIImageView = UIImageView(frame: frame)
        smallView.tag = 9
        smallView.roundView()
        smallView.image = self.locationImageView.image
        let center: CGPoint =
            CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)
        smallView.center = center
        smallView.alpha = 0
        self.addSubview(smallView)
        UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseIn, animations: {
            smallView.alpha = 1 }, completion:{_ in})
    }
    
    func recogSwipe(sender: UISwipeGestureRecognizer) {
        if sender.direction == .Left {
            delegate?.handleSwipeLeft(self, sender: sender)
        } else if sender.direction == .Right {
            delegate?.handleSwipeRight(self, sender: sender)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        longPress =
            UILongPressGestureRecognizer(
                target: self, action: #selector(LocationView.longTap(_:)))
        longPress!.allowableMovement = self.bounds.width/8
        leftSwipe = UISwipeGestureRecognizer(
            target: self, action: #selector(LocationView.recogSwipe(_:)))
        leftSwipe?.direction = .Left
        rightSwipe = UISwipeGestureRecognizer(
            target: self, action: #selector(LocationView.recogSwipe(_:)))
        rightSwipe?.direction = .Right
        self.addGestureRecognizer(longPress!)
        self.addGestureRecognizer(rightSwipe!)
        self.addGestureRecognizer(leftSwipe!)
        self.roundView()
        nameViewSetup()
        nameLabelSetup()
        mainImageViewSetup()
        setupStarsView()
        ratingViewSetup()
    }
    
    func loadData() {
        dataSource?.loadDataFor(self)
        dataSource?.requestImage(self)
    }
    
    func clearIcons() {
        if let left = iconLeft { left.removeFromSuperview() }
        if let center = iconCenter { center.removeFromSuperview() }
        if let right = iconRight { right.removeFromSuperview() }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DualView: UIView {
    
    var rhs: UIView?
    var rhs_icon: UIImageView?
    var lhs: UIView?
    var lhs_icon: UIImageView?
    
    static let BGColor: UIColor? =
    UIColor(red:242/255.0, green:222/255.0, blue: 220/225.0, alpha:1.0)
    
    private func setupViews(frame: CGRect) {
        let width: CGFloat = frame.size.width/2
        let lhs_frame: CGRect = CGRectMake(0, 0, width, frame.size.height)
        let rhs_frame: CGRect = CGRectMake(width, 0, width, frame.size.height)
        rhs = UIView(frame: rhs_frame)
        lhs = UIView(frame: lhs_frame)
        rhs?.backgroundColor = DualView.BGColor
        lhs?.backgroundColor = DualView.BGColor
        setupViewIcons(frame)
        self.addSubview(rhs!)
        self.addSubview(lhs!)
    }
    
    private func setupViewIcons(frame: CGRect) {
        let width: CGFloat = frame.size.width/2
        let lhs_icon_x: CGFloat = frame.size.width/6
        let rhs_icon_x: CGFloat = frame.size.width/3
        let iconFrame: CGRect = CGRectMake(0, 0, width/4, width/4)
        rhs_icon = UIImageView(frame: iconFrame)
        rhs_icon?.image = UIImage(named: "PhoneFilled-100")
        rhs_icon?.center = CGPointMake(rhs_icon_x, frame.height/2)
        rhs?.addSubview(rhs_icon!)
        
        lhs_icon = UIImageView(frame: iconFrame)
        lhs_icon?.image = UIImage(named: "MarkerFilled-100")
        lhs_icon?.center = CGPointMake(lhs_icon_x, frame.height/2)
        lhs?.addSubview(lhs_icon!)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews(frame)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}












