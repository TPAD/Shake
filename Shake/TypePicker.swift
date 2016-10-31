//
//  TypePicker.swift
//  Shake
//
//  Created by Antonio Padilla on 10/27/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

import Foundation

protocol TypePickerDelegate: class {
    func setDesiredLocation(using: TypePicker)
}

/*
 *  TypePicker class used in initial view controller
 *  It allows the user to choose the location type 
 *  they want to query in call to google location api
 *
 */
class TypePicker: UIView {
    
    var view: UIView!
    @IBOutlet weak var tableView: UITableView!
    var choicesArray: [String] = LocationTypes.other
    weak var delegate: TypePickerDelegate?
    var chosen: String?
    
    // MARK: - View state
    enum State {
        case `default`          // OTHER is default
        case fun
        case misc
        case need
    }
    
    var tab: State = .default {
        didSet {
            switch (tab) {
            case .default:
                choicesArray = LocationTypes.other
                break
            case .fun:
                choicesArray = LocationTypes.fun
                break
            case .misc:
                choicesArray = LocationTypes.miscellaneous
                break
            case .need:
                choicesArray = LocationTypes.need
                break
            }
            tableView.reloadData()
        }
    }
    
    // MARK: - View initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
        tab = .default
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
        
    }
    
    private func nibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
    }
    
    private func loadViewFromNib() -> UIView {
        return UINib(nibName: "TypePicker", bundle: nil)
            .instantiate(withOwner: self, options: nil)[0] as! UIView
    }
    
    // MARK: - button tab actions
    
    @IBAction func selectFun(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        deselectAllOther(except: sender)
        tab = .fun
    }
    
    @IBAction func selectMisc(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        deselectAllOther(except: sender)
        tab = .misc
    }
    
    @IBAction func selectNeed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        deselectAllOther(except: sender)
        tab = .need
    }

    @IBAction func selectOther(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        deselectAllOther(except: sender)
        tab = .default
    }
    
    private func deselectAllOther(except: UIButton) {
        for subview in view.subviews {
            if subview.isKind(of: UIButton.self) {
                if subview != except {
                    let button = subview as! UIButton
                    button.isSelected = false
                }
            }
        }
    }
    
    private func selectedButton() -> UIButton? {
        for subview in view.subviews {
            if subview.isKind(of: UIButton.self) {
                let button = subview as! UIButton
                if button.isSelected {
                    return button
                }
            }
        }
        return nil
    }
    
}

//MARK: - Protocol Extensions
extension TypePicker: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choicesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell().then {
            $0.backgroundColor = UIColor.clear
            $0.textLabel?.text = choicesArray[indexPath.row]
            $0.textLabel?.textColor = Colors.gBlue
        }
        return cell
    }
}

extension TypePicker: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        chosen = choicesArray[index]
        delegate?.setDesiredLocation(using: self)
    }
    
}












