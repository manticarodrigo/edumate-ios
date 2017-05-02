//
//  FilterTableViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/2/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class FilterTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var subjectCell: UITableViewCell!
    @IBOutlet weak var tutorCell: UITableViewCell!
    @IBOutlet weak var schoolCell: UITableViewCell!
    
    @IBOutlet weak var radiusCell: UITableViewCell!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var subjectPickerView: UIPickerView!
    @IBOutlet weak var tutorSwitch: UISwitch!
    @IBOutlet weak var schoolSwitch: UISwitch!
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    
    var subjectPickerVisible: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup subject cell
        self.subjectCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
        // Setup subject picker view
        self.subjectPickerView.delegate = self
        self.subjectPickerView.dataSource = self
        // Setup subject label
        DefaultsController.fetchSubjectInt { (subjectInt) in
            if let subjectInt = subjectInt {
                self.subjectLabel.text = Constants.data.subjects[subjectInt]
                self.subjectLabel.textColor = UIColor.black
            }
        }
        // Setup tutor cell
        self.tutorCell.imageView?.image = UIImage(named: "school.png")
        // Setup tutor switch
        DefaultsController.fetchTutorBool { (tutors) in
            if let tutors = tutors {
                self.tutorSwitch.isOn = tutors
            }
        }
        // Setup school cell
        self.schoolCell.imageView?.image = UIImage(named: "building.png")
        // Setup school switch
        DefaultsController.fetchSchoolBool { (restricted) in
            if let restricted = restricted {
                self.schoolSwitch.isOn = restricted
            }
        }
        // Setup radius cell
        self.radiusCell.imageView?.image = UIImage(named: "map.png")
        // Setup radius slider
        DefaultsController.fetchRadiusInt { (radius) in
            if let radius = radius {
                self.radiusSlider.setValue(Float(radius), animated: true)
            }
        }
        // Setup radius label
        let roundedValue = round(radiusSlider.value)
        self.radiusLabel.text = String(format: "%.0f", roundedValue) + " miles"
        // Remove empty cells
        self.tableView.tableFooterView = UIView()
        // Add gesture to hide keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.subjectPickerVisible = false
        self.subjectPickerView.isHidden = true
    }
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Picker View Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Constants.data.subjects.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Constants.data.subjects[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let subject = Constants.data.subjects[row]
        self.subjectLabel.text = subject
        self.subjectLabel.textColor = UIColor.black
        DefaultsController.setSubjectInt(int: row)
    }
    
    func showPickerCell() {
        self.subjectCell.accessoryView = UIImageView(image: UIImage(named: "up.png"))
        self.subjectPickerVisible = true
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        self.subjectPickerView.isHidden = false
        self.subjectPickerView.alpha = 0
        
        UIView.animate(withDuration: 0.25, animations: {
            self.subjectPickerView.alpha = 1
        })
    }
    
    func hidePickerCell() {
        self.subjectCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
        self.subjectPickerVisible = false
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        
        UIView.animate(withDuration: 0.25, animations: {
            self.subjectPickerView.alpha = 0
            }, completion: { (finished) in
                self.subjectPickerView.isHidden = true
        })
    }
    
    // MARK: - Switch Delegate
    
    @IBAction func schoolSwitchPressed(_ sender: AnyObject) {
        DefaultsController.setSchoolBool(bool: self.schoolSwitch.isOn)
    }
    
    @IBAction func tutorSwitchPressed(_ sender: Any) {
        DefaultsController.setTutorBool(bool: self.tutorSwitch.isOn)
    }
    
    // MARK: - Slider Delegate
    
    @IBAction func radiusSliderChanged(_ sender: AnyObject) {
        let roundedValue = round(radiusSlider.value)
        radiusLabel.text = String(format: "%.0f", roundedValue) + " miles"
        DefaultsController.setRadiusInt(int: Int(roundedValue))
    }
    
    // MARK: - Table View Data Source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height:CGFloat = 80
        
        if indexPath.row == 0 {
            // Intro text view
            DefaultsController.fetchSubjectInt(completion: { (subjectInt) in
                if subjectInt != nil {
                    height = 0
                } else {
                    height = 80
                }
            })
        }
        
        if indexPath.row == 2 {
            // Subject picker
            if let pickerVisible = self.subjectPickerVisible {
                height = pickerVisible ? 216 : 0
            }
        }
        
        return height
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            if self.subjectPickerVisible! {
                self.hidePickerCell()
            } else {
                self.showPickerCell()
            }
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
