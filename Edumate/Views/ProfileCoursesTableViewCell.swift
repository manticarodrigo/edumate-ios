//
//  ProfileCoursesTableViewCell.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 12/5/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class ProfileCoursesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var tutorLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.tutorLabel.layer.cornerRadius = 5
    }

}
