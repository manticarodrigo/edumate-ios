//
//  PlaceholderTextView.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 12/9/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class PlaceholderTextView : UITextView, UITextViewDelegate {
    
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
        self.placeholderLabel.frame.origin = CGPoint(x: 5, y: (self.font?.pointSize)! / 2)
        self.placeholderLabel.textColor = UIColor(white: 0, alpha: 0.25)
        self.placeholderLabel.isHidden = !self.text.isEmpty
        self.addSubview(self.placeholderLabel)
    }
    
}
