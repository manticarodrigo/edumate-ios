//
//  ContactTableViewCell.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 10/26/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class ContactTableViewCell: UITableViewCell {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imgView.layer.cornerRadius = self.imgView.frame.size.height/2
        self.countLabel.layer.cornerRadius = self.countLabel.frame.size.height/2
        self.countLabel.clipsToBounds = true
    }

}
