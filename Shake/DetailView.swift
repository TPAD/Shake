//
//  DetailView.swift
//  Shake
//
//  Created by Antonio Padilla on 10/29/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//


class InfoView: UIView { }                /* identifier for detail subviews */
class ReviewsContainerView: InfoView { }  /* identifier for reviews container */

/*  identifier for weekly hours
 *  contains labels to hold location open times information5
 */
class WeeklyHoursLabel: UIView {
    
    var day1: UILabel?; var monTimes: UILabel?
    var day2: UILabel?; var tueTimes: UILabel?
    var day3: UILabel?; var wedTimes: UILabel?
    var day4: UILabel?; var thuTimes: UILabel?
    var day5: UILabel?; var friTimes: UILabel?
    var day6: UILabel?; var satTimes: UILabel?
    var day7: UILabel?; var sunTimes: UILabel?
    
    var times: [String]? {
        didSet { if times != nil { loadTimes() } }
    }
    
    var rawData: [String]? {
        didSet { if rawData != nil {
                times = rawData.map({ removeWeekdayTextFrom(strings: $0) })
            }
        }
    }
    
    //MARK: - View initialization
    override init (frame: CGRect) {
        super.init(frame: frame)
        initDayLabels()
        initHoursLabels()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initDayLabels() {
        day1 = UILabel().then {
            $0.frame.size.width = (0.4)*frame.width
            $0.text = "Monday"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 16)
            $0.adjustsFontSizeToFitWidth = true
            $0.frame.size.height = $0.requiredHeight()
        }
        addSubview(day1!)
        day2 = UILabel().then { $0.text = "Tuesday"    }
        day3 = UILabel().then { $0.text = "Wednesday"  }
        day4 = UILabel().then { $0.text = "Thursday"   }
        day5 = UILabel().then { $0.text = "Friday"     }
        day6 = UILabel().then { $0.text = "Saturday"   }
        day7 = UILabel().then { $0.text = "Sunday"     }
        var days: [UILabel?] = [day1, day2, day3, day4, day5, day6, day7]
        for (i, day) in days.enumerated() {
            if i != 0 {
                day!.frame = day1!.frame
                day!.frame.origin.y = days[i-1]!.by(withOffset: 0)
                day!.font =  UIFont(name: "SanFranciscoText-Light", size: 16)
                day!.adjustsFontSizeToFitWidth = true
                day!.frame.size.height = day!.requiredHeight()
                addSubview(day!)
            }
        }
    }
    
    private func initHoursLabels() {
        monTimes = UILabel().then {
            $0.frame.origin.x = day1!.bx(withOffset: 0)
            $0.frame.size.width = (0.6)*frame.width
            $0.text = "Monday Hours"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 16)
            $0.adjustsFontSizeToFitWidth = true
            $0.frame.size.height = $0.requiredHeight()
            $0.textAlignment = .center
        }
        addSubview(monTimes!)
        tueTimes = UILabel().then { $0.text = "Tuesday Hours"   }
        wedTimes = UILabel().then { $0.text = "Wednesday Hours" }
        thuTimes = UILabel().then { $0.text = "Thursday Hours"  }
        friTimes = UILabel().then { $0.text = "Friday Hours"    }
        satTimes = UILabel().then { $0.text = "Saturday Hours"  }
        sunTimes = UILabel().then { $0.text = "Sunday Hours"    }
        var days: [UILabel?] = [day1, day2, day3, day4, day5, day6, day7]
        var hours: [UILabel?] = [monTimes, tueTimes, wedTimes, thuTimes, friTimes,
                                 satTimes, sunTimes]
        for (i, time) in hours.enumerated() {
            if i != 0 {
                time!.frame = monTimes!.frame
                time!.frame.origin.y = hours[i-1]!.by(withOffset: 0)
                time!.frame.origin.x = days[i-1]!.bx(withOffset: 0)
                time!.font = UIFont(name: "SanFranciscoText-Light", size: 16)
                time!.adjustsFontSizeToFitWidth = true
                time!.frame.size.height = time!.requiredHeight()
                time!.textAlignment = .center
                addSubview(time!)
            }
        }
    }
    
    private func removeWeekdayTextFrom(strings: [String]) -> [String] {
        var result: [String] = ["", "", "", "", "", "", ""]
        for (i, elem) in strings.enumerated() {
            let rep = "\(weekdays[i]) "
            result[i] = elem.replacingOccurrences(of: rep, with: "")
        }
        return result
    }
    
    private func loadTimes() {
        let hours: [UILabel?] = [monTimes, tueTimes, wedTimes, thuTimes, friTimes,
                                 satTimes, sunTimes]
        for (i, weekday) in hours.enumerated() {
            weekday!.text = times![i]
        }
    }
}


/* identifier for custom scroll view */
class SVCustom: UIScrollView {
    
    // medium firebrick is the default color
    var fillColor: CGColor = Colors.mediumFirebrick.cgColor
    
    init(frame: CGRect, color: CGColor) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        fillColor = color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let topView: CGRect = CGRect(x: 0, y: 0, width: rect.width,
                                     height: rect.height/2)
        context.setFillColor(fillColor)
        context.addRect(topView)
        context.drawPath(using: .fillStroke)
    }
}

protocol DetailViewDelegate: class {
    func redirectToCall()
    func redirectToWeb()
    func redirectToMaps()
    func saveLocation()
    func remove(detailView: DetailView)
}

protocol DetailViewDataSource: class {
    func setHoursFor(detailView: DetailView)
    func setInfoFor(detailView: DetailView)
    func setRatingFor(detailView: DetailView)
    func setReviewsFor(detailView: DetailView)
}

class DetailView: UIView, UIScrollViewDelegate {
    
    weak var delegate: DetailViewDelegate?
    weak var datasource: DetailViewDataSource?
    
    var scrollView: SVCustom!
    var svHeight: CGFloat!;     var svWidth: CGFloat!
    var gHeight: CGFloat!;      var iHeight: CGFloat!
    
    var isOpenView: InfoView!;  var addressView: InfoView!
    var hoursView: InfoView!;   var expandedHoursView: InfoView!
    var callView: InfoView!;    var saveView: InfoView!
    var reviewView: InfoView!;  var expandedReviewView: ReviewsContainerView!
    var ratingView: UIView!;    var weeklyHoursLabel: WeeklyHoursLabel!
    
    var exColHours: UIButton!;  var exColReviews: UIButton!
    var addressLabel: UILabel!; var nameLabel: UILabel!
    var typeLabel: UILabel!;    var isOpenLabel: UILabel!
    var numberLabel: UILabel!;  var saveLabel: UILabel!
    var reviewsLabel: UILabel!;
    
    var openIcon: UIImageView!; var addressIcon: UIButton!
    var callIcon: UIButton!;    var saveIcon: UIButton!
    var webIcon: UIButton!;     var webIconLabel: UILabel!
    
    var rating: Double = 0.0;   var svExpectedHeight: CGFloat = 0.0
    var hoursArray: [String]?;  var reviews: NSArray?
    var website: String?;       var isOpen: Bool?
    
    var hoursAvailable: Bool = false
    var hoursExpanded: Bool = false
    var reviewsExpanded: Bool = false
    var isFullScreen: Bool = false
    
    var svHeaderColor: UIColor?
    
    init(dframe: CGRect, svframe: CGRect, open: Bool?) {
        super.init(frame: dframe)
        if let notClosed = open {
            svHeaderColor = (notClosed) ?
                Colors.mediumSeaweed : Colors.mediumFirebrick
        } else {
            svHeaderColor = Colors.mediumFirebrick
        }
        svHeight = svframe.height
        svWidth = svframe.width
        gHeight = (0.1)*svframe.height
        iHeight = (0.5)*gHeight
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setup() {
        scrollView = SVCustom(frame: bounds, color: svHeaderColor!.cgColor)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.backgroundColor = UIColor.white
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        let swipeUp = UISwipeGestureRecognizer(target: self,
                                               action: #selector(adjustScrollView(_:)))
        swipeUp.direction = .up
        let swipeDown = UISwipeGestureRecognizer(target: self,
                                                 action: #selector(removeView(_:)))
        swipeDown.direction = .down
        self.addGestureRecognizer(swipeDown)
        self.addGestureRecognizer(swipeUp)
        initViews()
    }
    
    func loadData() {
        datasource?.setInfoFor(detailView: self)
        datasource?.setHoursFor(detailView: self)
        datasource?.setRatingFor(detailView: self)
    }
    
    func removeView(_ sender: UISwipeGestureRecognizer) {
        delegate?.remove(detailView: self)
    }
    
    func adjustScrollView(_ sender: UISwipeGestureRecognizer) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                let diff: CGFloat = self.svWidth - self.frame.width
                self.frame.size.width = self.svWidth
                self.frame.size.height = self.svHeight
                self.frame.origin.x = 0
                self.frame.origin.y = 0
                self.adjustViewWidths()
                self.webIcon.frame.origin.x += diff
                self.webIconLabel.frame.origin.x += diff
                // Adjusts hours when shown
                for subview in self.expandedHoursView.subviews {
                    if subview.isKind(of: WeeklyHoursLabel.self) {
                        subview.frame.origin.x += diff/2
                    }
                }
                // Adjusts reviews when shown
                for subview in self.expandedReviewView.subviews {
                    if subview.isKind(of: ReviewView.self) {
                        subview.frame.size.width = self.svWidth
                        for view in subview.subviews {
                            if !view.isKind(of: UIImageView.self) {
                                view.frame.origin.x += diff/2
                            } else {
                                view.frame.origin.x += diff/4
                            }
                        }
                    }
                }
                }, completion: {
                    (completed) in
                    if completed {
                        //self.draw(self.frame)
                    }
            })
        }
        isFullScreen = true
        if svExpectedHeight > scrollView.frame.height {
            scrollView.contentSize = CGSize(width: scrollView.frame.width,
                                            height: svExpectedHeight)
        }
    }
    
    // MARK: - header initializers
    
    /* MAIN HEADER */
    
    private func initOpenView() {
        isOpenView = InfoView().then {
            let h: CGFloat = (0.225)*svHeight
            $0.frame = CGRect(x: 0, y: 0, width: frame.height, height: h)
            $0.backgroundColor = svHeaderColor!
        }
        let bgView = InfoView().then {
            $0.frame = isOpenView.frame
            $0.backgroundColor = UIColor.white
        }
        scrollView.addSubview(isOpenView)
        scrollView.insertSubview(bgView, belowSubview: isOpenView)
        svExpectedHeight += isOpenView.frame.height
        initLocationName()
        initWebIcon()
        initRatingView()
        initTypeLabel()
    }
    
    private func initLocationName() {
        nameLabel = UILabel().then {
            $0.frame.size.width = (0.75)*frame.width
            $0.frame.size.height = (0.4)*isOpenView.frame.height
            $0.frame.origin.y = isOpenView.frame.origin.y + 32
            $0.frame.origin.x = 15
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.text = "Location Name"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 24)
            $0.textColor = UIColor.white
        }
        isOpenView.addSubview(nameLabel)
    }
    
    private func initWebIcon() {
        webIcon = UIButton().then {
            let y: CGFloat = isOpenView.frame.origin.y + 30
            let x: CGFloat = self.bx(withOffset: 0) - gHeight
            $0.frame =
                CGRect(x: x, y: y, width: (0.6)*gHeight, height: (0.6)*gHeight)
            $0.setImage(UIImage(named: "wwweb"), for: .normal)
            $0.addTarget(self, action: #selector(handleWebIconTapped(_:)),
                         for: .touchUpInside)
        }
        
        webIconLabel = UILabel().then {
            $0.frame.size.width = (1.25)*webIcon.frame.width
            $0.frame.origin.y = webIcon.by(withOffset: 5)
            $0.text = "WEBSITE"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 14)
            $0.textAlignment = .center
            $0.textColor = UIColor.white
            $0.sizeToFit()
            $0.center.x = webIcon.center.x
        }
        isOpenView.addSubview(webIcon)
        isOpenView.addSubview(webIconLabel)
    }
    
    func handleWebIconTapped(_ sender: UIButton) {
        delegate?.redirectToWeb()
    }
    
    private func initRatingView() {
        ratingView = UIView().then {
            let y: CGFloat = nameLabel.by(withOffset: 5)
            $0.frame = CGRect(x: 15, y: y, width: isOpenView.frame.width/4,
                              height: (0.3)*gHeight)
            $0.backgroundColor = UIColor.clear
        }
        isOpenView.addSubview(ratingView)
    }
    
    private func initTypeLabel() {
        typeLabel = UILabel().then {
            let y: CGFloat = ratingView.by(withOffset: 5)
            let width = (0.7)*frame.width
            $0.frame = CGRect(x: 15, y: y, width: width, height: 20)
            $0.text = "Location type"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 16)
            $0.adjustsFontSizeToFitWidth = true
            $0.textColor = UIColor.groupTableViewBackground
            $0.frame.size.height = $0.requiredHeight()
        }
        isOpenView.addSubview(typeLabel)
    }
    
    // MARK: - init address views
    private func initAddressView() {
        addressView = InfoView().then {
            let y: CGFloat = isOpenView.by(withOffset: 0)
            $0.frame = CGRect(x: 0, y: y, width: frame.width, height: gHeight)
            $0.backgroundColor = UIColor.white
        }
        svExpectedHeight += addressView.frame.height
        scrollView.addSubview(addressView)
        setAddressIcon()
        initAddressLabel()
    }
    
    private func setAddressIcon() {
        addressIcon = UIButton().then {
            $0.frame.size.height = iHeight
            $0.frame.size.width = iHeight
            $0.center.y = addressView.frame.height/2
            $0.frame.origin.x = 15
            $0.setImage(UIImage(named: "markicon"), for: .normal)
            $0.addTarget(self, action: #selector(handleLocationIconTapped(_:)),
                         for: .touchUpInside)
        }
        addressView.addSubview(addressIcon)
    }
    
    func handleLocationIconTapped(_ sender: UIButton) {
        delegate?.redirectToMaps()
    }
    
    private func initAddressLabel() {
        addressLabel = UILabel().then {
            $0.frame.origin.x = addressIcon.bx(withOffset: 15)
            $0.frame.size.width = (0.7)*addressView.frame.width
            $0.text = "Location Address"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 18)
            $0.adjustsFontSizeToFitWidth = true
            $0.textColor = UIColor.black
            $0.frame.size.height = $0.requiredHeight()
            $0.center.y = addressView.frame.height/2
        }
        addressView.addSubview(addressLabel)
    }
    
    //MARK: - init open hours views
    private func initHoursView() {
        hoursView = InfoView().then {
            let y: CGFloat = addressView.by(withOffset: 0)
            $0.frame = CGRect(x: 0, y: y, width: frame.width, height: gHeight)
            $0.backgroundColor = UIColor.white
        }
        scrollView.addSubview(hoursView)
        svExpectedHeight += hoursView.frame.height
        setTimeIcon()
        initTimeLabel()
        initExpandTimesButton()
    }
    
    private func setTimeIcon() {
        openIcon = UIImageView().then {
            $0.frame.size.height = iHeight
            $0.frame.size.width = iHeight
            $0.center.y = hoursView.frame.height/2
            $0.frame.origin.x = 15
            $0.image = UIImage(named: "timeicon")
        }
        hoursView.addSubview(openIcon)
    }
    
    private func initTimeLabel() {
        isOpenLabel = UILabel().then {
            $0.frame.origin.x = openIcon.bx(withOffset: 15)
            $0.frame.size.width = (0.5)*hoursView.frame.width
            $0.text = "Open Today"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 18)
            $0.adjustsFontSizeToFitWidth = true
            $0.textColor = UIColor.black
            $0.frame.size.height = $0.requiredHeight()
            $0.center.y = hoursView.frame.height/2
        }
        hoursView.addSubview(isOpenLabel)
    }
    
    private func initExpandTimesButton() {
        exColHours = UIButton().then {
            $0.frame.size.width = 0.5*(iHeight)
            $0.frame.size.height = 0.5*(iHeight)
            $0.center.y = hoursView.frame.height/2
            $0.frame.origin.x = isOpenLabel.bx(withOffset: 5)
            $0.setImage(UIImage(named: "expand"), for: .normal)
            $0.addTarget(self, action: #selector(exColHoursAction(_:)),
                         for: .touchUpInside)
        }
        hoursView.addSubview(exColHours)
    }
    
    private func expandHrsNoAnimationActions() {
        if !self.hoursExpanded {
            let widthB = self.isOpenLabel.frame.width
            isOpenLabel.text =
                isOpenLabel.text?.components(separatedBy: ":")[0]
            isOpenLabel.sizeToFit()
            let widthA = self.isOpenLabel.frame.width
            exColHours.frame.origin.x -= widthB-widthA
            exColHours.setImage(UIImage(named: "collapse"), for: .normal)
            if hoursAvailable { initWeeklyHours() }
        } else {
            isOpenLabel.frame.size.width = (0.5)*hoursView.frame.width
            isOpenLabel.adjustsFontSizeToFitWidth = true
            isOpenLabel.frame.size.height = isOpenLabel.requiredHeight()
            datasource?.setHoursFor(detailView: self)
            exColHours.frame.origin.x = isOpenLabel.bx(withOffset: 5)
            exColHours.setImage(UIImage(named: "expand"), for: .normal)
            for subview in expandedHoursView.subviews {
                if subview.isKind(of: WeeklyHoursLabel.self) {
                    subview.removeFromSuperview()
                }
            }
        }
    }
    
    func exColHoursAction(_ sender: UITapGestureRecognizer) {
        scrollView.contentSize = CGSize(width: scrollView.frame.width,
                                        height: scrollView.frame.height)
        let resizeHeight: CGFloat?
        expandHrsNoAnimationActions()
        if !hoursAvailable { return }
        resizeHeight = weeklyHoursLabel.frame.height
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                if !self.hoursExpanded {
                    for subview in self.scrollView.subviews {
                        if subview.frameIsBelow(view: self.expandedHoursView) {
                            subview.frame.origin.y += resizeHeight!
                        }
                    }
                    self.expandedHoursView.frame.size.height += resizeHeight!
                    self.svExpectedHeight += resizeHeight!
                } else {
                    self.expandedHoursView.frame.size.height -= resizeHeight!
                    self.svExpectedHeight -= resizeHeight!
                    for subview in self.scrollView.subviews {
                        if subview.frameIsBelow(view: self.expandedHoursView) {
                            subview.frame.origin.y -= resizeHeight!
                        }
                    }
                }
                if self.svExpectedHeight > self.scrollView.frame.height
                    && self.isFullScreen {
                    self.scrollView.contentSize.height = self.svExpectedHeight
                } else if self.svExpectedHeight < self.scrollView.frame.height {
                    if self.isFullScreen {
                        self.scrollView.contentSize.height = self.svHeight
                    }
                }
                self.hoursExpanded = !self.hoursExpanded
            })
        }
    }
    
    private func initExpandedHoursView() {
        expandedHoursView = InfoView().then {
            let y: CGFloat = hoursView.by(withOffset: 0)
            $0.frame = CGRect(x: 0, y: y, width: frame.width, height: 0)
            $0.backgroundColor = UIColor.white
        }
        scrollView.addSubview(expandedHoursView)
    }
    
    private func initWeeklyHours() {
        let width: CGFloat = (0.65)*hoursView.frame.width
        let height: CGFloat = (2.5)*hoursView.frame.height
        let frame: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        weeklyHoursLabel = WeeklyHoursLabel(frame: frame).then {
            $0.rawData = hoursArray!
            $0.center.x = hoursView.frame.width/2
            $0.frame.size.height = $0.day7!.by(withOffset: 0)
        }
        expandedHoursView.addSubview(weeklyHoursLabel)
    }
    
    // MARK: - init phone number views
    private func initCallView() {
        callView = InfoView().then {
            let y: CGFloat = expandedHoursView.by(withOffset: 0)
            $0.frame = CGRect(x: 0, y: y, width: frame.width, height: gHeight)
            $0.backgroundColor = UIColor.white
        }
        scrollView.addSubview(callView)
        svExpectedHeight += callView.frame.height
        setCallIcon()
        initNumberLabel()
    }
    
    private func setCallIcon() {
        callIcon = UIButton().then {
            $0.frame.size.height = iHeight
            $0.frame.size.width = iHeight
            $0.center.y = callView.frame.height/2
            $0.frame.origin.x = 15
            $0.setImage(UIImage(named: "phone-1"), for: .normal)
            $0.addTarget(self, action: #selector(handleCallIconTapped(_:)),
                         for: .touchUpInside)
        }
        callView.addSubview(callIcon)
    }
    
    func handleCallIconTapped(_ sender: UIButton) {
        delegate?.redirectToCall()
    }
    
    private func initNumberLabel() {
        numberLabel = UILabel().then {
            $0.frame.origin.x = callIcon.bx(withOffset: 15)
            $0.text = "(###) ###-####"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 18)
            $0.adjustsFontSizeToFitWidth = true
            $0.textColor = UIColor.black
            $0.sizeToFit()
            $0.center.y = callView.frame.height/2
        }
        callView.addSubview(numberLabel)
    }
    
    // MARK: - init save for later views
    private func initSaveView() {
        saveView = InfoView().then {
            let y: CGFloat = callView.by(withOffset: 0)
            $0.frame = CGRect(x: 0, y: y, width: frame.width, height: gHeight)
            $0.backgroundColor = UIColor.white
        }
        scrollView.addSubview(saveView)
        svExpectedHeight += saveView.frame.height
        setSaveIcon()
        initSaveLabel()
    }
    
    private func setSaveIcon() {
        saveIcon = UIButton().then {
            $0.frame.size.height = iHeight
            $0.frame.size.width = iHeight
            $0.center.y = saveView.frame.height/2
            $0.frame.origin.x = 15
            $0.setImage(UIImage(named: "star"), for: .normal)
            $0.addTarget(self, action: #selector(saveIconTapped(_:)),
                         for: .touchUpInside)
        }
        saveView.addSubview(saveIcon)
    }
    
    func saveIconTapped(_ sender: UIButton) {
        delegate?.saveLocation()
    }
    
    private func initSaveLabel() {
        saveLabel = UILabel().then {
            $0.frame.origin.x = saveIcon.bx(withOffset: 15)
            $0.text = "Save for Later"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 18)
            $0.adjustsFontSizeToFitWidth = true
            $0.textColor = UIColor.black
            $0.sizeToFit()
            $0.center.y = saveView.frame.height/2
        }
        saveView.addSubview(saveLabel)
    }
    
    
    // MARK: - init reviews
    private func initReviewView() {
        reviewView = InfoView().then {
            let y: CGFloat = saveView.by(withOffset: 0)
            $0.frame = CGRect(x: 0, y: y, width: frame.width, height: gHeight)
            $0.backgroundColor = UIColor.white
        }
        scrollView.addSubview(reviewView)
        svExpectedHeight += reviewView.frame.height
        initReviewLabel()
        initExpandReviewsButton()
    }
    
    private func initReviewLabel() {
        reviewsLabel = UILabel().then {
            $0.frame.origin.x = 15
            $0.text = "Reviews (#)"
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 18)
            $0.textColor = UIColor.black
            $0.sizeToFit()
            $0.center.y = reviewView.frame.height/2
        }
        reviewView.addSubview(reviewsLabel)
    }
    
    private func initExpandReviewsButton() {
        exColReviews = UIButton().then {
            $0.frame.size.width = 0.5*(iHeight)
            $0.frame.size.height = 0.5*(iHeight)
            $0.center.y = reviewView.frame.height/2
            $0.frame.origin.x = reviewsLabel.bx(withOffset: 10)
            $0.setImage(UIImage(named: "expand"), for: .normal)
            $0.addTarget(self, action: #selector(exColRevAction(_:)),
                         for: .touchUpInside)
        }
        reviewView.addSubview(exColReviews)
    }
    
    private func expandRevNoAnimationActions() {
        if !self.reviewsExpanded {
            exColReviews.setImage(UIImage(named: "collapse"), for: .normal)
            datasource?.setReviewsFor(detailView: self)
        } else {
            exColReviews.setImage(UIImage(named: "expand"), for: .normal)
        }
    }
    
    func exColRevAction(_ sender: UITapGestureRecognizer) {
        expandRevNoAnimationActions()
        let requiredHeight = expandedReviewView.sumOfSubviewHeights() + 15
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                if !self.reviewsExpanded {
                    self.expandedReviewView.frame.size.height += requiredHeight
                    self.svExpectedHeight += requiredHeight
                } else {
                    self.svExpectedHeight -= requiredHeight
                    self.expandedReviewView.frame.size.height -= requiredHeight
                    for subview in self.expandedReviewView.subviews {
                        if subview.isKind(of: ReviewView.self) {
                            subview.removeFromSuperview()
                        }
                    }
                }
                if self.svExpectedHeight > self.scrollView.frame.height
                    && self.isFullScreen {
                    self.scrollView.contentSize.height = self.svExpectedHeight
                } else if self.svExpectedHeight < self.scrollView.frame.height {
                    if self.isFullScreen {
                        self.scrollView.contentSize.height = self.svHeight
                    }
                }
                self.reviewsExpanded = !self.reviewsExpanded
            })
        }
    }
    
    private func initReviewExpanded() {
        expandedReviewView = ReviewsContainerView().then {
            let y: CGFloat = reviewView.by(withOffset: 0)
            $0.frame = CGRect(x: 0, y: y, width: frame.width, height: 0)
            $0.backgroundColor = UIColor.white
        }
        scrollView.addSubview(expandedReviewView)
    }
    
    private func initViews() {
        initOpenView()
        initAddressView()
        initHoursView()
        initExpandedHoursView()
        initCallView()
        initSaveView()
        initReviewView()
        initReviewExpanded()
    }
    
    private func adjustViewWidths() {
        for subview in scrollView.subviews {
            if subview.isKind(of: InfoView.self) {
                subview.frame.size.width = svWidth
            }
        }
    }
}


/*
 * This class corresponds to review views displayed within DetailView
 * specifically within expandedReviewView. It should be initialized with
 * a dictionary containing reviews JSON from goolgle API
 *
 */
class ReviewView: UIView {
    
    var label: UILabel!
    var nameLabel: UILabel!
    var ratingLabel: UILabel!
    var starView: CosmosView!
    var imageView: UIImageView!
    var ratingView: UIView!
    
    init(frame: CGRect, rawData: NSDictionary?) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        initImageView()
        initNameLabel()
        initReviewLabel()
        initRatingView()
        initRatingLabel()
        initReviewStars()
        setReviewText(rawData: rawData)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initImageView() {
        imageView = UIImageView().then {
            $0.frame.size.width = (0.4)*frame.height
            $0.frame.size.height = (0.4)*frame.height
            $0.backgroundColor = UIColor.cyan
            $0.center.y = frame.height/2
            $0.frame.origin.x = 15
            $0.roundView(borderWidth: 0)
        }
        addSubview(imageView)
    }
    
    private func initNameLabel() {
        nameLabel = UILabel().then {
            $0.frame.size.width = (0.5)*frame.width
            $0.text = "Name"
            $0.font = UIFont(name: "SanFranciscoText-Medium", size: 12.0)
            $0.adjustsFontSizeToFitWidth = true
            $0.frame.size.height = $0.requiredHeight()
            $0.frame.origin.x = imageView.bx(withOffset: 10)
            $0.frame.origin.y = imageView.frame.origin.y
        }
        addSubview(nameLabel)
    }
    
    private func initReviewLabel() {
        label = UILabel().then {
            $0.frame.size.width = (0.8)*bounds.width
            $0.frame.origin.y = nameLabel.by(withOffset: 2)
            $0.frame.origin.x = imageView.bx(withOffset: 10)
            $0.text = "Review Text"
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.font = UIFont(name: "SanFranciscoText-Light", size: 12)
        }
        addSubview(label)
    }
    
    private func initRatingView() {
        ratingView = UIView().then {
            $0.frame.size.height = (0.1)*frame.size.height
            $0.frame.size.width = (6)*$0.frame.height
            $0.frame.origin.x = label.frame.origin.x
            $0.backgroundColor = UIColor.clear
        }
        addSubview(ratingView)
    }
    
    private func initRatingLabel() {
        ratingLabel = UILabel().then {
            $0.frame.size.width = (1/6)*ratingView.frame.width
            $0.frame.size.height = ratingView.frame.height
            $0.text = "0.0"
            $0.font = UIFont(name: "SanFranciscoText-Medium", size: 8.0)
            $0.adjustsFontSizeToFitWidth = true
            $0.textColor = UIColor.orange
            $0.backgroundColor = UIColor.clear
        }
        ratingView.addSubview(ratingLabel)
    }
    
    private func initReviewStars() {
        let height: CGFloat = ratingView.frame.height
        let width: CGFloat = (5/6)*ratingView.frame.width
        let frame: CGRect = CGRect(x: ratingLabel.bx(withOffset: 5),
                                   y: 0, width: width, height: height)
        
        starView = CosmosView(frame: frame)
        starView.starSize = 8
        starView.settings.fillMode = .precise
        starView.frame.size.width = starView.intrinsicContentSize.width
        starView.frame.size.height = starView.intrinsicContentSize.height
        starView.settings.emptyBorderColor = UIColor.orange
        starView.settings.filledBorderColor = UIColor.orange
        starView.settings.filledColor = UIColor.orange
        starView.isUserInteractionEnabled = false
        starView.center.y = ratingView.frame.height/2
        ratingView.addSubview(starView)
    }
    
    private func setReviewText(rawData: NSDictionary?) {
        if let data = rawData {
            label.text = "\"\(data["text"] as! String)\""
            nameLabel.text = data["author_name"] as? String ?? "Name"
            if let rating = data["rating"] as? Double {
                ratingLabel.text = "\(rating)"
                starView.rating = rating
            } else {
                ratingLabel.text = "0.0"
                starView.rating = 0
            }
            ratingLabel.sizeToFit()
            ratingLabel.center.y = ratingView.frame.height/2
            label.frame.size.height = label.requiredHeight()
            ratingView.frame.origin.y = label.by(withOffset: 5)
            if let url = data["profile_photo_url"] as? String {
                setReviewerImage(url: url)
            } else {
                imageView.image = UIImage(named: "user")
            }
            let diff = ratingView.by(withOffset: 0) - frame.height
            self.frame.size.height += diff
        }
    }
    
    private func setReviewerImage(url: String?) {
        if let URL = url {
            let new = "https:" + URL
            Search.requestImageFromURL(url: new, target: imageView)
        }
    }
}
