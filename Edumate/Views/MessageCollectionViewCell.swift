//
//  MessageTableViewCell.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/17/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import AVFoundation

class MessageCollectionViewCell: UICollectionViewCell {
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightSemibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.gray
        label.isHidden = true
        return label
    }()
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = UIColor.clear
        tv.textColor = .white
        tv.isEditable = false
        return tv
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.data.lightBlue
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.addDropShadow()
        return view
    }()
    
    let readLabel: UILabel = {
        let label = UILabel()
        label.text = "READ"
        label.font = UIFont.systemFont(ofSize: 8, weight: UIFontWeightBold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        label.backgroundColor = UIColor.clear
        label.textColor = Constants.data.darkBlue
        label.isHidden = true
        return label
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    
    var textViewTopAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.bubbleView)
        self.addSubview(self.nameLabel)
        self.addSubview(self.textView)
        self.addSubview(self.readLabel)
        self.addSubview(self.profileImageView)
        
        self.bubbleWidthAnchor = self.bubbleView.widthAnchor.constraint(equalToConstant: 200)
        self.bubbleWidthAnchor?.isActive = true
        
        self.bubbleViewRightAnchor = self.bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        self.bubbleViewRightAnchor?.isActive = true
        
        self.bubbleViewLeftAnchor = self.bubbleView.leftAnchor.constraint(equalTo: self.profileImageView.rightAnchor, constant: 8)
        
        self.bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        self.nameLabel.topAnchor.constraint(equalTo: self.bubbleView.topAnchor, constant: 5).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.bubbleView.leftAnchor, constant: 12).isActive = true
        self.nameLabel.rightAnchor.constraint(equalTo: self.bubbleView.rightAnchor, constant: -8).isActive = true
        
        self.textViewTopAnchor = self.textView.topAnchor.constraint(equalTo: self.topAnchor)
        self.textViewTopAnchor?.isActive = true
        
        self.textView.leftAnchor.constraint(equalTo: self.bubbleView.leftAnchor, constant: 8).isActive = true
        self.textView.rightAnchor.constraint(equalTo: self.bubbleView.rightAnchor).isActive = true
        self.textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        self.readLabel.rightAnchor.constraint(equalTo: self.bubbleView.rightAnchor, constant: -6).isActive = true
        self.readLabel.bottomAnchor.constraint(equalTo: self.bubbleView.bottomAnchor, constant: -2).isActive = true
        
        self.profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        self.profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        self.profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
