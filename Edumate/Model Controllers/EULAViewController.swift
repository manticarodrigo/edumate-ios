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
    @IBOutlet weak var acceptButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup eula text view
        self.eulaTextView.layer.cornerRadius = 10
        // Setup accept button
        self.acceptButton.stylize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Scroll eula text view to top
        self.eulaTextView.scrollRangeToVisible(NSRange(location:0, length:0))
    }

}
