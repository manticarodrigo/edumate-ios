//
//  CourseCollectionViewCell.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/21/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class CourseCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var nameLabel: TopAlignLabel!
    @IBOutlet weak var dotView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 10
        self.cardView.layer.cornerRadius = 10
        self.cardView.addDropShadow()
        self.dotView.layer.cornerRadius = self.dotView.frame.size.height/2
    }
}
