//
//  LocationView.swift
//  Shake
//
//  Created by Tony Padilla on 6/11/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

protocol DualViewDelegate: class {
    
    func navigationAction(_ sender: UIGestureRecognizer,
                          onView: DualView)
    func callLocationAction(_ sender: UIGestureRecognizer,
                            onView: DualView)
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
        rhs?.backgroundColor = Helper.Colors.green
        lhs?.backgroundColor = Helper.Colors.blue
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
    
    func userHasTapped(_ sender: UIGestureRecognizer) {
        let callFrame: CGRect = rhs!.frame
        let mapFrame: CGRect = lhs!.frame
        let tapPoint: CGPoint = sender.location(in: self)
        if callFrame.contains(tapPoint) {
            delegate?.callLocationAction(sender, onView: self)
        } else if mapFrame.contains(tapPoint) {
            delegate?.navigationAction(sender, onView: self)
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

class DetailView: UIView {
    
    var view: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }
    
    private func loadViewFromNib() -> UIView {
        return UINib(nibName: "GPLaceDetail", bundle: nil)
            .instantiate(withOwner: self, options: nil)[0] as! UIView
    }
    
    private func nibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
}










