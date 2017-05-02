//
//  TopAlignLabel.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 12/10/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class TopAlignLabel: UILabel {
    
    override func drawText(in rect: CGRect) {
        guard self.text != nil else {
            return super.drawText(in: rect)
        }
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.hyphenationFactor = 1
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        
        let attributedText = NSAttributedString.init(string: self.text!, attributes: [NSFontAttributeName : self.font, NSParagraphStyleAttributeName : paragraph])
        self.attributedText = attributedText
        
        var newRect = rect
        newRect.size.height = attributedText.boundingRect(with: rect.size, options: .usesLineFragmentOrigin, context: nil).size.height
        
        if self.numberOfLines != 0 {
            newRect.size.height = min(newRect.size.height, CGFloat(self.numberOfLines) * self.font.lineHeight)
        }
        
        super.drawText(in: newRect)
    }
    
}
