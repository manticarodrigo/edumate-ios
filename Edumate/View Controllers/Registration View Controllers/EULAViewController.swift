//
//  EULAViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/12/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class EULAViewController: UIViewController {

    @IBOutlet weak var eulaTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup eula image view
        self.eulaTextView.layer.cornerRadius = 10
        // Setup accept button
        self.acceptButton.stylize()
    }

}
