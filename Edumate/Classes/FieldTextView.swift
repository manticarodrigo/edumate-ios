//
//  FieldTextView.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 12/9/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class FieldTextView : UITextView, UITextViewDelegate {
    
    override var contentSize: CGSize {
        didSet {
            var topCorrection = (self.bounds.size.height - self.contentSize.height * self.zoomScale) / 2.0
            topCorrection = max(0, topCorrection)
            self.contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
        }
    }
    
    let placeholderLabel = UILabel()
    var placeholder: String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupView()
    }
    
    private func setupView() {
        self.placeholderLabel.text = self.placeholder ?? "Tap to start typing..."
        self.placeholderLabel.textAlignment = self.textAlignment
        self.placeholderLabel.font = self.font
        self.placeholderLabel.sizeToFit()
        var topCorrection = (self.bounds.size.height - self.contentSize.height * self.zoomScale) / 2.0
        topCorrection = max(0, topCorrection)
        self.placeholderLabel.frame = CGRect(x: 0, y: -topCorrection, width: self.frame.width, height: self.frame.height)
        self.placeholderLabel.textColor = UIColor(white: 0, alpha: 0.25)
        self.placeholderLabel.isHidden = !self.text.isEmpty
        self.addSubview(self.placeholderLabel)
    }
    
}
