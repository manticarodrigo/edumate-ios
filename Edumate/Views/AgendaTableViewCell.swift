//
//  AgendaTableViewCell.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 11/11/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class AgendaTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var assignmentLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var courseLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        self.bubbleView.layer.cornerRadius = 10
        self.bubbleView.addDropShadow()
    }

}
