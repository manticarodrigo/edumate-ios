//
//  StyledSegmentedControl.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 11/10/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

@IBDesignable class StyledSegmentedControl: UIControl {
    
    fileprivate var labels = [UILabel]()
    var thumbView = UIView()
    
    var items : [String] = ["Item 1", "Item 2"] {
        didSet {
            self.setupLabels()
        }
    }
    
    @IBInspectable var item1 : String = "Item 1" {
        didSet {
            self.items = [self.item1, self.item2]
        }
    }
    
    @IBInspectable var item2 : String = "Item 2" {
        didSet {
            self.items = [self.item1, self.item2]
        }
    }
    
    var selectedIndex : Int = 0 {
        didSet {
            self.displayNewSelectedIndex()
        }
    }
    
    @IBInspectable var selectedLabelColor : UIColor = UIColor.black {
        didSet {
            self.setSelectedColors()
        }
    }
    
    @IBInspectable var unselectedLabelColor : UIColor = UIColor.white {
        didSet {
            self.setSelectedColors()
        }
    }
    
    @IBInspectable var thumbColor : UIColor = UIColor.white {
        didSet {
            self.setSelectedColors()
        }
    }
    
    @IBInspectable var cornerRadius : Int = 10 {
        didSet {
            self.layer.cornerRadius = CGFloat(self.cornerRadius) // frame.height / 2
            self.thumbView.layer.cornerRadius = CGFloat(self.cornerRadius) // thumbView.frame.height / 2
        }
    }
    
    @IBInspectable var borderColor : UIColor = UIColor.white {
        didSet {
            self.layer.borderColor = self.borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth : Int = 2 {
        didSet {
            self.layer.borderWidth = CGFloat(self.borderWidth)
        }
    }
    
    @IBInspectable var font : UIFont! = UIFont.systemFont(ofSize: 12) {
        didSet {
            self.setFont()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        self.setupView()
    }
    
    func setupView() {
        self.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).cgColor
        self.layer.borderWidth = 2
        // backgroundColor = UIColor.clear
        self.setupLabels()
        self.addIndividualItemConstraints(self.labels, mainView: self, padding: 0)
        self.insertSubview(self.thumbView, at: 0)
    }
    
    func setupLabels() {
        
        for label in self.labels {
            label.removeFromSuperview()
        }
        
        self.labels.removeAll(keepingCapacity: true)
        
        for index in 1...self.items.count {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
            label.text = self.items[index - 1]
            label.backgroundColor = UIColor.clear
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
            label.textColor = index == 1 ? self.selectedLabelColor : self.unselectedLabelColor
            label.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(label)
            self.labels.append(label)
        }
        
        self.addIndividualItemConstraints(self.labels, mainView: self, padding: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var selectFrame = self.bounds
        let newWidth = selectFrame.width / CGFloat(self.items.count)
        selectFrame.size.width = newWidth
        self.thumbView.frame = selectFrame
        self.thumbView.backgroundColor = self.thumbColor
        self.thumbView.addDropShadow()
        
        self.displayNewSelectedIndex()
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        let location = touch.location(in: self)
        
        var calculatedIndex : Int?
        for (index, item) in labels.enumerated() {
            if item.frame.contains(location) {
                calculatedIndex = index
            }
        }
        
        if calculatedIndex != nil {
            self.selectedIndex = calculatedIndex!
            sendActions(for: .valueChanged)
        }
        return false
    }
    
    func displayNewSelectedIndex() {
        for (index, item) in self.labels.enumerated() {
            item.textColor = self.unselectedLabelColor
        }
        
        var label = self.labels[self.selectedIndex]
        label.textColor = self.selectedLabelColor
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [], animations: {
            
            self.thumbView.frame = label.frame
            
        }, completion: nil)
    }
    
    func addIndividualItemConstraints(_ items: [UIView], mainView: UIView, padding: CGFloat) {
        
        for (index, button) in items.enumerated() {
            
            let topConstraint = NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: mainView, attribute: .top, multiplier: 1.0, constant: 0)
            
            let bottomConstraint = NSLayoutConstraint(item: button, attribute: .bottom, relatedBy: .equal, toItem: mainView, attribute: .bottom, multiplier: 1.0, constant: 0)
            
            var rightConstraint : NSLayoutConstraint!
            
            if index == items.count - 1 {
                rightConstraint = NSLayoutConstraint(item: button, attribute: .right, relatedBy: .equal, toItem: mainView, attribute: .right, multiplier: 1.0, constant: -padding)
            } else {
                let nextButton = items[index+1]
                rightConstraint = NSLayoutConstraint(item: button, attribute: .right, relatedBy: .equal, toItem: nextButton, attribute: .left, multiplier: 1.0, constant: -padding)
            }
            
            var leftConstraint : NSLayoutConstraint!
            
            if index == 0 {
                leftConstraint = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: mainView, attribute: .left, multiplier: 1.0, constant: padding)
            } else {
                let prevButton = items[index-1]
                leftConstraint = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: prevButton, attribute: .right, multiplier: 1.0, constant: padding)
                let firstItem = items[0]
                let widthConstraint = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: firstItem, attribute: .width, multiplier: 1.0  , constant: 0)
                
                mainView.addConstraint(widthConstraint)
            }
            mainView.addConstraints([topConstraint, bottomConstraint, rightConstraint, leftConstraint])
        }
    }
    
    func setSelectedColors(){
        for item in self.labels {
            item.textColor = self.unselectedLabelColor
        }
        
        if self.labels.count > 0 {
            self.labels[0].textColor = self.selectedLabelColor
        }
        
        self.thumbView.backgroundColor = self.thumbColor
    }
    
    func setFont(){
        for item in self.labels {
            item.font = self.font
        }
    }
}
