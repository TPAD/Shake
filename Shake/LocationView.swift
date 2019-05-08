//
//  LocationView.swift
//  Shake
//
//  Created by Tony Padilla on 6/11/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//
import Foundation
import UIKit
import CoreLocation


/*  MARK: -  Protocol LocationViewDelegate
 *
 *  conforming class: DestinationViewController
 *  Establishes communication between Location object
 *  and DestinationViewVontroller (delegation of tasks)
 *
 */
protocol LocationViewDelegate: class {
    func longPressAction(_ view: Location, sender: UIGestureRecognizer?)
    func updateView(_ view: Location)
    func haltLocationUpdates()
}

/*  MARK: - UIView Location
 *
 *  Location object built using interface builder.
 *  Displays information retrieved from NSDictionary (response from google api)
 *  if information requested exists.
 *
 */
class Location: UIView, DetailViewDataSource {
    
    var view: UIView!
    var dualView: DualView?             /* Initialized when user long taps */
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var ratingView: UIView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var cost: UILabel!
    
    // JSON object as a dictionary
    var rawData: [String:AnyObject]? {
        didSet {
            name.text = getName()
            name.adjustsFontSizeToFitWidth = true
            setPriceLvl()
            openRn()
            getPhoto()
            coordinates = getCoords()
            phoneNumber = getPhoneNum()
            setRating()
            address = getAddress()
            getHours()
            setReviews()
            getTypes()
            getWebsite()
        }
    }
    
    // delegates tasks to DestinationViewController
    weak var delegate: LocationViewDelegate?
    
    var coordinates: (Double, Double)? {
        didSet {
            if coordinates != nil {
                appDelegate.dest = CLLocationCoordinate2D(latitude: coordinates!.0,
                                                          longitude: coordinates!.1)
            }
        }
    }
    var phoneNumber: String?
    var address: String?
    var formatAddress: String?
    var isOpen: Bool = false
    var reviews: NSArray?
    var weeklyHours: Array<String>?
    var openPeriods: Array<[String:AnyObject]>?
    var types: Array<String>?
    var mainType: String?
    var website: String?
    
    enum State {
        case `default`
        case pressed
    }
    
    var state: State = .default {
        didSet {
            // remove preview
            if let v = self.viewWithTag(9) {
                UIView.animate(withDuration: 0.35, delay: 0,
                               options: .curveEaseOut,
                               animations: { v.alpha = 0 },
                               completion: {
                                _ in
                                v.removeFromSuperview()
                })
            }
            switch state {
            // remove dualView in the default state
            case .default:
                if let v = self.viewWithTag(10) {
                    UIView.animate(withDuration: 0.35, delay: 0,
                                   options: .curveEaseOut,
                                   animations: { v.alpha = 0 },
                                   completion: {
                                    _ in
                                    v.removeFromSuperview()
                    })
                }
            // draw dualView in the pressed state
            case .pressed:
                addPreviewToSubview()
                view.addSubview(dualView!)
                UIView.animate(withDuration: 0.35, delay: 0,
                               options: .curveEaseIn,
                               animations: { self.dualView!.alpha = 1 },
                               completion: nil)
            }
        }
    }
    
    /*
     *  Methods used for proper intialization of Location object
     *
     */
    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
        let longPress =
            UILongPressGestureRecognizer(
                target: self, action: #selector(self.longTap(_:)))
        longPress.allowableMovement = self.bounds.width/8
        addGestureRecognizer(longPress)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }
    
    private func nibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.roundView(borderWidth: 6)
        addSubview(view)
    }
    
    private func loadViewFromNib() -> UIView {
        return UINib(nibName: "GPlace", bundle: nil)
            .instantiate(withOwner: self, options: nil)[0] as! UIView
    }
    
    /*
     *  Methods used to retrieve information from JSON as a Disctionary
     *
     */
    
    // Retrieves coordinates used for compass in DestinationViewController
    // in conjunction with location updates
    private func getCoords() -> (Double, Double)? {
        if let geo = rawData?["geometry"] as? [String:AnyObject] {
            if let location = geo["location"] as? [String:AnyObject] {
                if let lat = location["lat"], let lng = location["lng"] {
                    return (lat as! Double, lng as! Double)
                } else {
                    return nil
                }
            }
        }
        return nil
    }
    
    private func getName() -> String? {
        if let data = rawData?["name"] as? String {
            return data
        }
        return nil
    }
    
    // Updates Location object based on whether or not location is open
    private func openRn() {
        if let hours = rawData?["opening_hours"] as? [String:AnyObject] {
            if hours["open_now"] == nil {
                setSchemeForUnavailableTimes()
                return
            } else {
                let open: Bool? = hours["open_now"] as? Bool
                if open == nil {
                    setSchemeForUnavailableTimes()
                    return
                }
                self.isOpen = (open!) ? true:false
                ratingView.backgroundColor = (open!) ?
                    Colors.mediumSeaweed: Colors.mediumFirebrick
                name.textColor = (open!) ?
                    Colors.mediumSeaweed: Colors.mediumFirebrick
            }
        } else {
            setSchemeForUnavailableTimes()
        }
    }
    
    private func setSchemeForUnavailableTimes() {
        self.isOpen = false
        ratingView.backgroundColor = Colors.mediumFirebrick
        name.textColor = Colors.mediumFirebrick
    }
    
    // retrieves location photos, but only displays one on Location object
    private func getPhoto() {
        if let photos = rawData?["photos"] as? NSArray {
            // TODO: - there isn't necessarily just one of these
            // pass them on to DetailView
            if let ref_obj = photos[0] as? [String:AnyObject] {
                if let ref = ref_obj["photo_reference"] as? String {
                    let width = Int(self.image.frame.width)
                    let key: String = appDelegate.getApiKey()
                    let session = URLSession.shared
                    let params: Parameters = ["maxwidth":"\(width)",
                                              "photoreference":"\(ref)",
                                              "key":"\(key)"]
                    var search = GoogleSearch(type: .PHOTO, parameters: params)
                    search.makeRequest(session, handler: responseHandler)
                    
                }
            }
        } else { image.image = UIImage(named: "station") }
    }
    
    private func responseHandler(data: Data?) {
        if data == nil { //TODO: - 
        }
        let image = UIImage(data: data!)
        if image == nil { //TODO: -
        } else {
            DispatchQueue.main.async {
                self.image.image = image!
            }
        }
        
    }
    
    private func getPhoneNum() -> String? {
        if let data = rawData?["formatted_phone_number"] as? String {
            return data
        }
        return nil
    }
    
    private func setPriceLvl() {
        cost.text = ""
        if let count = rawData?["price_level"] as? Int {
            for _ in 0..<count { cost.text?.append("$") }
        }
    }
    
    private func setRating() {
        view.viewWithTag(7)?.removeFromSuperview()
        let starview: CosmosView = CosmosView(frame: ratingView.frame)
        starview.starSize = 15
        starview.tag = 7
        starview.frame.size.width = starview.intrinsicContentSize.width
        starview.center.x = view.center.x
        starview.frame.origin.y = (0.06)*view.frame.height
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
    
    private func getAddress() -> String? {
        if let data = rawData?["vicinity"] as? String,
            let fadd = rawData!["formatted_address"] as? String {
            formatAddress = fadd
            var temp: String = ""
            for char in data {
                if (char == ",") { break }
                temp.append(char)
            }
            return temp
        }
        return nil
    }
    
    private func setReviews() {
        if let reviews = rawData?["reviews"] as? NSArray {
            self.reviews = reviews
        }
    }
    
    private func getHours() {
        if let hours = rawData?["opening_hours"] as? [String:AnyObject] {
            if let periods = hours["periods"] as? NSArray,
                let text = hours["weekday_text"] as? NSArray {
                openPeriods = periods as? Array<[String:AnyObject]>
                weeklyHours = text as? Array<String>
            }
        }
    }
    
    private func getWebsite() {
        if let url = rawData?["website"] as? String {
            website = url
        }
    }
    
    private func getTypes() {
        if let data = rawData?["types"] as? NSArray {
            types = data as? Array<String>
        }
    }
    
    // basic displacement of Location object in a repeated animation
    // TODO: - slight improvements
    private func shakeAnimation() {
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
    
    // switch used by self and delegate
    func toggleState() {
        state = (state == .default) ? .pressed:.default
    }
    
    // adds a preview of the location over a DualView that is animated underneath
    func addPreviewToSubview() {
        let widgetWidth: CGFloat = (0.35)*self.frame.width
        let frame: CGRect = CGRect(x: 0, y: 0, width: widgetWidth, height: widgetWidth)
        let smallView: UIImageView = UIImageView(frame: frame)
        smallView.tag = 9
        smallView.roundView(borderWidth: 6)
        smallView.image = self.image.image
        let center: CGPoint =
            CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        smallView.center = center
        smallView.alpha = 0
        self.addSubview(smallView)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseIn, animations: {
            smallView.alpha = 1 }, completion:{_ in})
    }
    
    /*
     *  Methods used by the delegate (DestinationViewController)
     *
     */
    func requestViewUpdate() {
        shakeAnimation()
        delegate?.updateView(self)
        setNeedsDisplay()
        layoutIfNeeded()
    }
    
    @objc func longTap(_ sender: UIGestureRecognizer?) {
        delegate?.longPressAction(self, sender: sender)
    }
    
    func stopLocationUpdates() {
        delegate?.haltLocationUpdates()
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
    
    
    //MARK: - DetailViewDataSource
    /*
     *  Location object serves as a data source for DetailView
     *
     */
    // retrieves all necessary availability times
    func setHoursFor(detailView: DetailView) {
        if let arr = weeklyHours {
            detailView.hoursAvailable = true
            detailView.hoursArray = arr
            let i = Helper.dayOfWeek() - 1
            let day = weekdays[i]
            var string = arr[i].replacingOccurrences(of: day, with: "")
            // CASE location open 24 hours
            if string.components(separatedBy: ":").count == 1 {
                string = string.replacingOccurrences(of: " Open", with: "")
            }
            string = string.replacingOccurrences(of: ":00", with: "")
            detailView.isOpenLabel.text = (isOpen) ?
                "Open Today: " + "\(string)": "Closed"
            if !isOpen {
                detailView.isOpenLabel.sizeToFit()
                detailView.exColHours.frame.origin.x =
                    detailView.isOpenLabel.bx(withOffset: 5)
            }
        } else {
            detailView.isOpenLabel.text = "n/a"
            detailView.exColHours.removeFromSuperview()
            detailView.isOpenView.backgroundColor = Colors.mediumFirebrick
        }
    }
    
    // Retrieves the following: Name, currently open, address, types
    // phone number, number of reviews, and website
    func setInfoFor(detailView: DetailView) {
        detailView.nameLabel.text = name.text
        let addr = formatAddress?.replacingOccurrences(of: ", USA", with: "")
        detailView.addressLabel.text = addr ?? "n/a"
        if let types = types {
            if var type = types.first {
                type = type.replacingOccurrences(of: "_", with: " ")
                detailView.typeLabel.text = type.capitalizingFirstLetter()
            }
        } else { detailView.typeLabel.text = "n/a" }
        detailView.numberLabel.text = phoneNumber ?? "n/a"
        if let rev = reviews {
            detailView.reviews = rev
            detailView.reviewsLabel.text = "Reviews (\(rev.count))"
        } else {
            detailView.reviewsLabel.text = "Reviews (n/a)"
            detailView.exColReviews.removeFromSuperview()
        }
        detailView.reviewsLabel.sizeToFit()
        detailView.exColReviews.frame.origin.x =
            detailView.reviewsLabel.bx(withOffset: 5)
        detailView.website = website
    }
    
    // sets the rating on DetailView
    func setRatingFor(detailView: DetailView) {
        let starview: CosmosView = CosmosView(frame: detailView.ratingView.frame)
        starview.starSize = 12
        starview.frame.size.width = starview.intrinsicContentSize.width
        starview.settings.fillMode = .precise
        starview.frame.origin.y = detailView.nameLabel.by(withOffset: 10)
        starview.settings.emptyBorderColor = UIColor.yellow
        starview.settings.filledBorderColor = UIColor.yellow
        starview.settings.filledColor = UIColor.yellow
        starview.isUserInteractionEnabled = false
        detailView.isOpenView.addSubview(starview)
        if let rating = rawData?["rating"] as? Double {
            starview.rating = rating
        } else {
            starview.rating = 0
        }
    }
    
    // retrieves reviews and initializes them within expandedReviewView
    // in ReviewView objects
    func setReviewsFor(detailView: DetailView) {
        var yoffset: CGFloat = -15
        if let reviews = detailView.reviews {
            for review in reviews {
                let frame: CGRect = CGRect(x: 0, y: yoffset,
                                           width: detailView.frame.width,
                                           height: (1.5)*detailView.gHeight)
                let reviewView =
                    ReviewView(frame: frame, rawData: review as? [String:AnyObject])
                reviewView.setNeedsDisplay()
                yoffset += reviewView.frame.height
                detailView.expandedReviewView.addSubview(reviewView)
            }
        }
    }
    
}

/*  MARK: -  Protocol DualViewDelegate
 *
 *  conforming class: DestinationViewController
 *  Establishes communication between DualView object
 *  and DestinationViewVontroller (delegation of tasks)
 *
 */
protocol DualViewDelegate: class {
    func navigationAction()
    func callLocationAction()
}

/*  MARK: -  UIView DualView
 *  
 *  Initializes over Location object when long press is recognized
 *  within bounds of Location object. Contains an image of location
 *  as well as two buttons for navigation and phone call
 *
 */
class DualView: UIView {
    
    var rhs: UIView?
    var rhs_icon: UIImageView?
    var lhs: UIView?
    var lhs_icon: UIImageView?
    
    weak var delegate: DualViewDelegate?
    
    fileprivate func setupViews(_ frame: CGRect) {
        let width: CGFloat = frame.size.width/2
        let lhs_frame: CGRect = CGRect(x: 0, y: 0, width: width,
                                       height: frame.size.height)
        let rhs_frame: CGRect = CGRect(x: width, y: 0, width: width,
                                       height: frame.size.height)
        rhs = UIView(frame: rhs_frame)
        lhs = UIView(frame: lhs_frame)
        rhs?.backgroundColor = Colors.green
        lhs?.backgroundColor = Colors.blue
        setupViewIcons(frame)
        self.addSubview(rhs!)
        self.addSubview(lhs!)
    }
    
    fileprivate func setupViewIcons(_ frame: CGRect) {
        let width: CGFloat = frame.size.width/2
        let lhs_icon_x: CGFloat = frame.size.width/6
        let rhs_icon_x: CGFloat = frame.size.width/3
        let iconFrame: CGRect = CGRect(x: 0, y: 0, width: width/4, height: width/4)
        rhs_icon = UIImageView(frame: iconFrame)
        rhs_icon?.image = UIImage(named: "Phone")
        rhs_icon?.center = CGPoint(x: rhs_icon_x, y: frame.height/2)
        rhs?.addSubview(rhs_icon!)
        
        lhs_icon = UIImageView(frame: iconFrame)
        lhs_icon?.image = UIImage(named: "Marker")
        lhs_icon?.center = CGPoint(x: lhs_icon_x, y: frame.height/2)
        lhs?.addSubview(lhs_icon!)
    }
    
    @objc func userHasTapped(_ sender: UIGestureRecognizer) {
        let callFrame: CGRect = rhs!.frame
        let mapFrame: CGRect = lhs!.frame
        let tapPoint: CGPoint = sender.location(in: self)
        if callFrame.contains(tapPoint) {
            delegate?.callLocationAction()
        } else if mapFrame.contains(tapPoint) {
            delegate?.navigationAction()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews(frame)
        let tap =
            UITapGestureRecognizer(target: self,
                                   action: #selector(userHasTapped(_:)))
        addGestureRecognizer(tap)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}




