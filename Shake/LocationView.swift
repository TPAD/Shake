//
//  LocationView.swift
//  Shake
//
//  Created by Tony Padilla on 6/11/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

//MARK: - LVDATASOURCE
protocol LocationViewDataSource: class {
    func loadDataFor(_ view: LocationView)
    func requestImage(_ view: LocationView)
}

//MARK: - LVDELEGATE
protocol LocationViewDelegate: class {
    func initializeLongPress(_ view: LocationView, sender: UIGestureRecognizer)
    func handleSwipeRight(_ view: LocationView, sender: UISwipeGestureRecognizer)
    func handleSwipeLeft(_ view: LocationView, sender: UISwipeGestureRecognizer)
}

//MARK: - LocationView
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
                Helper.Colors.mediumSeaweed: Helper.Colors.mediumFirebrick
            }
        }
    }
    
    weak var dataSource: LocationViewDataSource?
    weak var delegate: LocationViewDelegate?
    
    var locationImageView: UIImageView = UIImageView()
    var nameView: UIView = UIView()
    var starView: UIView = UIView()
    var locationName: UILabel = UILabel()
    var ratingView: RatingView?
    var numberOfIcons: Int = 0
    let white: UIColor =
        UIColor(red:255/255.0, green:255/255.0, blue:255/255.0, alpha:0.7)
    
    var longPress: UILongPressGestureRecognizer?
    var leftSwipe: UISwipeGestureRecognizer?
    var rightSwipe: UISwipeGestureRecognizer?
    
    enum State {
        case `default`
        case pressed
    }
    
    var state: State = .default {
        didSet {
            if let v = self.viewWithTag(9) {
                UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut,
                animations: { v.alpha = 0 }, completion: {
                    _ in
                    v.removeFromSuperview()
                })
            }
            switch state {
            case .default:
                for subview in subviews {
                    if subview.isKind(of: DualView.self) {
                        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut,
                        animations: { subview.alpha = 0 }, completion: {
                            _ in
                            subview.removeFromSuperview()
                        })
                    }
                }
            case .pressed:
                dualView = DualView(frame: self.bounds)
                dualView!.alpha = 0
                dualView!.delegate = self
                addSubview(dualView!)
                UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseIn,
                animations: { self.dualView!.alpha = 1 }, completion: { _ in })
            }
        }
    }
    
    func toggleState() {
        state = (state == .default) ? .pressed:.default
    }
    
    func undoSwipe(onView view: DualView, sender: UISwipeGestureRecognizer) {
        view.delegate?.undoSwipeAction(onView: view, sender: sender)
        
    }
    
    fileprivate func setLocationName() {
        if let name = data!["name"] as? String {
            locationName.text = name
            locationName.font = UIFont(name: "PingFangHK-Regular", size: 30)
            locationName.textColor = locationIsOpenNow() ?
                //medium seaweed
                UIColor(red:60/255.0, green:179/255.0, blue:113/255.0, alpha: 0.8):
                //medium firebrick
                UIColor(red:205/255.0, green:35/255.0, blue:35/255.0, alpha:0.8)
            locationName.adjustsFontSizeToFitWidth = true
            locationName.bounds.size.height = locationName.requiredHeight()
        }
    }
    
    fileprivate func setRating() {
        if let stars = data!["rating"] {
            ratingView!.rating = stars as! Float
        } else {
            ratingView!.rating = 0.0
        }
    }
    
    fileprivate func nameLabelSetup() {
        let width: CGFloat = 0.75*(nameView.frame.width)
        let height:CGFloat = 0.3*(nameView.frame.height)
        let frame = CGRect(x: 0, y: 0, width: width, height: height)
        locationName.frame = frame
        locationName.center.x = nameView.center.x
        locationName.textAlignment = .center
        nameView.addSubview(locationName)
    }
    
    fileprivate func nameViewSetup() {
        let y: CGFloat = 0.7*(self.frame.height)
        let width: CGFloat = self.frame.width
        let height: CGFloat = 0.3*(self.frame.height)
        let frame: CGRect =
            CGRect(x: 0, y: y, width: width, height: height)
        nameView.frame = frame
        nameView.backgroundColor = white
        self.addSubview(nameView)
    }
    
    fileprivate func mainImageViewSetup() {
        let y: CGFloat = (0.12)*self.frame.height
        let width: CGFloat = self.frame.width
        let height: CGFloat = (0.58)*self.frame.height
        let frame: CGRect = CGRect(x: 0, y: y, width: width, height: height)
        locationImageView.frame = frame
        locationImageView.image = UIImage(named: "station")
        self.addSubview(locationImageView)
    }
    
    fileprivate func setupStarsView() {
        let height: CGFloat = 0.12*(self.frame.height)
        let width: CGFloat = self.frame.width
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        starView.frame = frame
        starView.backgroundColor = white
        self.addSubview(starView)
    }
    
    fileprivate func ratingViewSetup() {
        let width: CGFloat = (0.35)*starView.frame.width
        let height: CGFloat = width/5
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        ratingView = RatingView(frame: frame).then {
            $0.center.x = self.starView.center.x
            $0.center.y = self.starView.center.y + height/5
            
        }
        starView.addSubview(ratingView!)
    }
    
    fileprivate func locationHasCarRepair() -> Bool {
        if let types = data!["types"] as? [String] {
            if types.contains("car_repair") { return true }
        }
        return false
    }
    
    fileprivate func locationHasATM() -> Bool {
        if let types = data!["types"] as? [String] {
            if types.contains("atm") { return true }
        }
        return false
    }
    
    fileprivate func locationIsConvenienceStore() -> Bool {
        if let types = data!["types"] as? [String] {
            if types.contains("conveneince_store") { return true }
        }
        return false
    }
    
    fileprivate func locationIsOpenNow() -> Bool {
        if let hours = data!["opening_hours"] as? NSMutableDictionary {
            if let currentlyOpen = hours["open_now"] as? Int {
                return (currentlyOpen == 0) ? false:true
            }
        }
        return false
    }
    
    fileprivate func setNumberOfIcons(_ locationHas:(_ repair: Bool, _ ATM: Bool, _ store: Bool) -> Void) {
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
        locationHas(carRepair, atm, isStore)
    }
    
    fileprivate func drawIcons() {
        setNumberOfIcons({
            (repair, ATM, store) -> Void in
            let width: CGFloat = (0.085)*self.nameView.frame.width
            let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: width)
            let imageView1 = UIImageView(frame: frame)
            let imageView2 = UIImageView(frame: frame)
            let imageView3 = UIImageView(frame:frame)
            let x: CGFloat = (0.5)*self.nameView.frame.width
            let y: CGFloat = (0.5)*(self.nameView.frame.height + width)
          
            if self.numberOfIcons == 3 {
                self.iconLeft = imageView1
                self.iconCenter = imageView2
                self.iconRight = imageView3
                let center: CGPoint = CGPoint(x: x, y: y)
                let center_left: CGPoint = CGPoint(x: x-1.5*width, y: y)
                let center_right: CGPoint = CGPoint(x: x+1.5*width, y: y)
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
                let center_left: CGPoint = CGPoint(x: x-2*width/3, y: y)
                let center_right: CGPoint = CGPoint(x: x+2*width/3, y: y)
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
                let center: CGPoint = CGPoint(x: x, y: y)
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
    
    func longTap(_ sender: UIGestureRecognizer) {
        delegate?.initializeLongPress(self, sender: sender)
        
    }
    
    func addPreviewToSubview() {
        
        let widgetWidth: CGFloat = (0.35)*self.frame.width
        let frame: CGRect = CGRect(x: 0, y: 0, width: widgetWidth, height: widgetWidth)
        let smallView: UIImageView = UIImageView(frame: frame)
        smallView.tag = 9
        smallView.roundView()
        smallView.image = self.locationImageView.image
        let center: CGPoint =
            CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        smallView.center = center
        smallView.alpha = 0
        self.addSubview(smallView)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseIn, animations: {
            smallView.alpha = 1 }, completion:{_ in})
    }
    
    func recogSwipe(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == .left {
            delegate?.handleSwipeLeft(self, sender: sender)
        } else if sender.direction == .right {
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
        leftSwipe?.direction = .left
        rightSwipe = UISwipeGestureRecognizer(
            target: self, action: #selector(LocationView.recogSwipe(_:)))
        rightSwipe?.direction = .right
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

//MARK: - DVDelegate
extension LocationView: DualViewDelegate {
    
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

protocol DualViewDelegate: class {
    func undoSwipeAction(onView view: DualView, sender: UISwipeGestureRecognizer)
}

//MARK: - DualView
class DualView: UIView {
    
    var rhs: UIView?
    var rhs_icon: UIImageView?
    var lhs: UIView?
    var lhs_icon: UIImageView?
    
    weak var delegate: DualViewDelegate?
    
    static let BGColor: UIColor? =
    UIColor(red:242/255.0, green:222/255.0, blue: 220/225.0, alpha:1.0)
    
    fileprivate func setupViews(_ frame: CGRect) {
        let width: CGFloat = frame.size.width/2
        let lhs_frame: CGRect = CGRect(x: 0, y: 0, width: width, height: frame.size.height)
        let rhs_frame: CGRect = CGRect(x: width, y: 0, width: width, height: frame.size.height)
        rhs = UIView(frame: rhs_frame)
        lhs = UIView(frame: lhs_frame)
        rhs?.backgroundColor = DualView.BGColor
        lhs?.backgroundColor = DualView.BGColor
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
        rhs_icon?.image = UIImage(named: "PhoneFilled-100")
        rhs_icon?.center = CGPoint(x: rhs_icon_x, y: frame.height/2)
        rhs?.addSubview(rhs_icon!)
        
        lhs_icon = UIImageView(frame: iconFrame)
        lhs_icon?.image = UIImage(named: "MarkerFilled-100")
        lhs_icon?.center = CGPoint(x: lhs_icon_x, y: frame.height/2)
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

//MARK: - RatingView
class RatingView: UIView {
    
    fileprivate var stars: [UIImageView] = [UIImageView]()
    var rating: Float = 0 {
        didSet {
            maxRating = ceil(rating)
            if rating > 5 { maxRating = 5 }
            else if rating < 0 { maxRating = 0 }
            loadRating()
            print(rating)
            
        }
    }
    fileprivate var maxRating: Float?
    
    fileprivate func initStars() {
        let width: CGFloat = self.bounds.size.width/5
        let height: CGFloat = self.bounds.size.height
        let center_x: CGFloat = self.bounds.size.width/10
        let center_y: CGFloat = self.bounds.size.height/2
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        for i in 1...5 {
            let j: CGFloat = CGFloat(2*i - 1)
            stars.append(UIImageView().then {
                $0.image = (UIImage(named: "Star"))
                $0.frame = frame
                $0.center = CGPoint(x: j*center_x, y: center_y)
                self.addSubview($0)
                })
        }
    }
    
    func loadRating() {
        let max: Int = Int(maxRating!)
        for i in 0..<max {
            let imageView = stars[i]
            imageView.image = UIImage(named: "StarFilled")
            if rating >= Float(i+1) {
                imageView.layer.mask = nil
                imageView.isHidden = false
            } else if rating > Float(i) && rating < Float(i+1) {
                let maskLayer = CALayer()
                let maskWidth: CGFloat =
                    CGFloat(1.0-(Float(max)-rating))*imageView.bounds.width
                let maskHeight: CGFloat = imageView.bounds.size.height
                maskLayer.frame = CGRect(x: 0, y: 0, width: maskWidth, height: maskHeight)
                maskLayer.backgroundColor = UIColor.black.cgColor
                maskLayer.contents = UIImage(named: "StarFilled")!.cgImage
                imageView.layer.mask = maskLayer
                imageView.isHidden = false
            } else {
                imageView.layer.mask = nil
                imageView.isHidden = true
            }
        }
        if max == 0 {
            for i in 0..<stars.count {
                stars[i].image = UIImage(named: "Star")
                stars[i].layer.mask = nil
            }
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initStars()
        self.backgroundColor = UIColor.clear
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}











