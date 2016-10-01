//
//  Loader.swift
//  Shake
//
//  Created by Antonio Padilla on 9/26/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

import Foundation

/****************************
  everything commented out
  will be implemented
        later
 ***************************/

//MARK: - LVDELEGATE
protocol LocationViewDelegate: class {
    func initializeLongPress(_ view: Location, sender: UIGestureRecognizer?)
    func handleSwipeRight(_ view: Location, sender: UISwipeGestureRecognizer)
    func handleSwipeLeft(_ view: Location, sender: UISwipeGestureRecognizer)
    func updateView(_ view: Location)
}

class Location: UIView {
    
    var view: UIView!
    var dualView: DualView?
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var ratingView: UIView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cost: UILabel!

    var rawData: NSDictionary? {
        didSet {
            name.text = getName()
            name.adjustsFontSizeToFitWidth = true
            setPriceLvl()
            openRn()
            setRating()
            getPhoto()
            coordinates = getCoords()
            phoneNumber = getPhoneNum()
        }
    }
    
    weak var delegate: LocationViewDelegate?
    
    var coordinates: (Double?, Double?)?
    var phoneNumber: String?
    /*lazy var reviews: NSArray?  = { return self.getReviews() }()
    lazy var weeklyHours: NSDictionary? = { return self.getHours() }()
    lazy var reference: String? = { return self.getRef() }()
    lazy var address: String? = { return self.getAddress() }()
    var more_pics: NSArray? = nil
    lazy var types: NSArray? = { return self.getTypes() }()*/
    
    enum State {
        case `default`
        case pressed
    }
    
    var state: State = .default {
        didSet {
            // remove preview
            if let v = self.viewWithTag(9) {
                UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut,
                               animations: { v.alpha = 0 }, completion: {
                                _ in
                                v.removeFromSuperview()
                })
            }
            switch state {
            // remove dualView in the default state
            case .default:
                if let v = self.viewWithTag(10) {
                    UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut,
                                   animations: { v.alpha = 0 }, completion: {
                                    _ in
                                    v.removeFromSuperview()
                    })
                }
            // draw dualView in the pressed state
            case .pressed:
                dualView = DualView(frame: self.bounds)
                dualView!.tag = 10
                dualView!.alpha = 0
                dualView!.delegate = self
                view.addSubview(dualView!)
                UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseIn,
                               animations: { self.dualView!.alpha = 1 }, completion: { _ in })
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
        let longPress =
            UILongPressGestureRecognizer(
                target: self, action: #selector(self.longTap(_:)))
        longPress.allowableMovement = self.bounds.width/8
        let leftSwipe = UISwipeGestureRecognizer(
            target: self, action: #selector(Location.swipeHandler(_:)))
        leftSwipe.direction = .left
        let rightSwipe = UISwipeGestureRecognizer(
            target: self, action: #selector(Location.swipeHandler(_:)))
        rightSwipe.direction = .right
        addGestureRecognizer(longPress)
        addGestureRecognizer(rightSwipe)
        addGestureRecognizer(leftSwipe)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }
    
    private func nibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.roundView()
        addSubview(view)
    }
    
    private func loadViewFromNib() -> UIView {
        return UINib(nibName: "GPlace", bundle: nil)
            .instantiate(withOwner: self, options: nil)[0] as! UIView
    }
    
    private func getCoords() -> (Double?, Double?) {
        if let geo = rawData!["geometry"] as? NSDictionary {
             if let location = geo["location"] as? NSDictionary {
                if let lat = location["lat"], let lng = location["lng"] {
                    return (lat as? Double, lng as? Double)
                }
            }
        }
        return (nil, nil)
    }
    
    private func getName() -> String? {
        if let data = rawData?["name"] as? String {
            return data
        }
        return nil
    }
    
    private func openRn() {
        if let hours = rawData!["opening_hours"] as? NSDictionary {
            if let open = hours["open_now"] as? Int {
                ratingView.backgroundColor = (open == 1) ?
                    Helper.Colors.mediumSeaweed: Helper.Colors.mediumFirebrick
                name.textColor = (open == 1) ?
                    Helper.Colors.mediumSeaweed: Helper.Colors.mediumFirebrick
            }
        } else {
            ratingView.backgroundColor = Helper.Colors.mediumFirebrick
            name.textColor = Helper.Colors.mediumFirebrick
        }
    }
    
    private func getPhoto() {
        if let photos = rawData!["photos"] as? NSArray {
            // TODO: - there isn't necessarily one of these
            if let ref_obj = photos[0] as? NSDictionary {
                if let ref = ref_obj["photo_reference"] as? String {
                    Search.retrieveImageByReference(ref: ref, target: self.image, maxWidth: Int(self.image.frame.width))
                }
            }
        } else {
            image.image = UIImage(named: "station")
        }
    }
    
    private func getPhoneNum() -> String? {
        if let data = rawData!["formatted_phone_number"] as? String {
            print(data)
            return data
        }
        return nil
    }
    
    private func setPriceLvl() {
        cost.text = ""
        if let count = rawData?["price_level"] as? Int {
            for _ in 0..<count {
                cost.text?.append("$")
            }
        }
    }
    
    private func setRating() {
        let starview: CosmosView = CosmosView(frame: ratingView.frame)
        starview.starSize = 15
        starview.frame.size.width = starview.intrinsicContentSize.width
        starview.center.x = view.center.x
        starview.frame.origin.y = (0.05)*view.frame.height
        starview.settings.fillMode = .precise
        starview.settings.emptyBorderColor = UIColor.yellow
        starview.settings.filledBorderColor = UIColor.yellow
        starview.settings.filledColor = UIColor.yellow
        starview.isUserInteractionEnabled = false
        ratingView.addSubview(starview)
        if let rating = rawData?["rating"] as? Double {
            starview.rating = rating
        } else {
            starview.rating = 0
        }
    }
    
    /*private func getReviews() -> NSArray? {
        if let reviews = rawData!["reviews"] as? NSArray {
            return reviews
        }
        return nil
    }
    
    private func getHours() -> NSDictionary? {
        //TODO:- get the hours
        return nil
    }
    
    private func getRef() -> String? {
        if let ref = rawData!["reference"] as? String {
            return ref
        }
        return nil
    }
    
    private func getAddress() -> String? {
        if let data = rawData!["vicinity"] as? String {
            /*if let range = data.range(of: ", Pittsburgh", options: .backwards) {
                data.removeSubrange(range)
                return data
            }*/
            return data
        }
        return nil
    }
    
    private func getTypes() -> NSArray? {
        if let data = rawData!["types"] as? NSArray {
            return data
        }
        return nil
    } */
    //TODO: - Get more images to choose from in case of errors 
    
    func toggleState() {
        state = (state == .default) ? .pressed:.default
    }
    
    func undoSwipe(onView view: DualView, sender: UISwipeGestureRecognizer) {
        view.delegate?.undoSwipeAction(onView: view, sender: sender)
    }
    
    func addPreviewToSubview() {
        
        let widgetWidth: CGFloat = (0.35)*self.frame.width
        let frame: CGRect = CGRect(x: 0, y: 0, width: widgetWidth, height: widgetWidth)
        let smallView: UIImageView = UIImageView(frame: frame)
        smallView.tag = 9
        smallView.roundView()
        smallView.image = self.image.image
        let center: CGPoint =
            CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        smallView.center = center
        smallView.alpha = 0
        self.addSubview(smallView)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseIn, animations: {
            smallView.alpha = 1 }, completion:{_ in})
    }
    
    func requestViewUpdate() {
        shakeAnimation()
        delegate?.updateView(self)
        setNeedsDisplay()
        layoutIfNeeded()
    }
    
    func longTap(_ sender: UIGestureRecognizer?) {
        delegate?.initializeLongPress(self, sender: sender)
    }
    
    func swipeHandler(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == .left {
            delegate?.handleSwipeLeft(self, sender: sender)
        } else if sender.direction == .right {
            delegate?.handleSwipeRight(self, sender: sender)
        }
    }
    
}

extension Location {
    
    func shakeAnimation() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 15,
                                                       y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 15,
                                                     y: self.center.y))
        layer.add(animation, forKey: "position")

    }
    
    func distanceFromLocation(_ location: CLLocation) -> String {
        if let lat = coordinates?.0, let lng = coordinates?.1 {
            let locationA = CLLocation(latitude: lat, longitude: lng)
            let distance = locationA.distanceInMilesFromLocation(location)
            let dString = String(format: "%.2fmi", distance)
            return dString
        } else {
            return ""
        }
    }
}

//MARK: - DVDelegate
extension Location: DualViewDelegate {
    
    func undoSwipeAction(onView view: DualView, sender: UISwipeGestureRecognizer) {
        if sender.direction == .left {
            if let dualView = self.dualView {
                dualView.lhs!.backgroundColor = DualView.BGColor
                dualView.lhs_icon!.image = UIImage(named: "MarkerFilled-100")
            }
        } else if sender.direction == .right {
            if let dualView = self.dualView {
                dualView.rhs!.backgroundColor = DualView.BGColor
                dualView.rhs_icon!.image = UIImage(named: "PhoneFilled-100")
            }
        }
        if let preview: UIView = self.viewWithTag(9) {
            UIView.animate(withDuration: 0.35, animations: {
                preview.center.x = self.bounds.width/2
                preview.center.y = self.bounds.height/2
            })
        }
    }
}














