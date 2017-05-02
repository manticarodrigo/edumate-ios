//
//  CourseTableViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 6/27/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class CourseTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UITextViewDelegate, SearchTextFieldDelegate {
    
    var course: Course?
    
    @IBOutlet weak var subjectCell: UITableViewCell!
    @IBOutlet weak var termCell: UITableViewCell!
    @IBOutlet weak var inviteCell: UITableViewCell!
    @IBOutlet weak var assignmentsCell: UITableViewCell!
    @IBOutlet weak var adminCell: UITableViewCell!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameTextView: FieldTextView!
    @IBOutlet weak var descriptionTextView: PlaceholderTextView!
    @IBOutlet weak var universityTextField: SearchTextField!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var subjectPickerView: UIPickerView!
    @IBOutlet weak var termLabel: UILabel!
    @IBOutlet weak var termPickerView: UIPickerView!
    @IBOutlet weak var memberLabel: UILabel!
    @IBOutlet weak var assignmentLabel: UILabel!
    @IBOutlet weak var adminLabel: UILabel!
    
    var subjectPickerVisible: Bool?
    var termPickerVisible: Bool?
    var userSelectionType: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup NavBar
        self.stylizeNavBar()
        // Setup name text field
        self.nameTextView.delegate = self
        self.nameTextView.text = nil
        self.nameTextView.placeholder = "Enter course name"
        // Setup university text field
        let frame = CGRect(x: 0, y: 44, width: self.view.frame.size.width, height: 800)
        self.universityTextField.delegate = self
        self.universityTextField.searchDelegate = self
        self.universityTextField.popoverSize = frame
        // Setup description text view
        self.descriptionTextView.delegate = self
        self.descriptionTextView.text = nil
        self.descriptionTextView.placeholder = "Add description"
        // Setup subject picker view
        self.subjectPickerView.delegate = self
        self.subjectPickerView.dataSource = self
        // Setup term picker view
        self.termPickerView.delegate = self
        self.termPickerView.dataSource = self
        // Remove empty cells
        self.tableView.tableFooterView = UIView()
        // Add gesture to dismiss keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide subject picker
        self.subjectPickerVisible = false
        self.subjectPickerView.isHidden = true
        // Hide term picker
        self.termPickerVisible = false
        self.termPickerView.isHidden = true
        // Check for course
        if let course = course {
            self.setupCourse(course)
        } else {
            // Setup create button
            let createButton = UIBarButtonItem(title: "CREATE", style: .plain, target: self, action: #selector(createCourse))
            createButton.tintColor = UIColor.white
            self.navigationItem.rightBarButtonItem = createButton
            // Enable input
            self.nameTextView.isEditable = true
            self.universityTextField.isEnabled = true
            // Add cell accessory views
            self.subjectCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
            self.termCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
            self.inviteCell.accessoryView = UIImageView(image: UIImage(named: "right.png"))
            self.assignmentsCell.accessoryView = UIImageView(image: UIImage(named: "right.png"))
            self.adminCell.accessoryView = UIImageView(image: UIImage(named: "right.png"))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Dismiss keyboard
        self.dismissKeyboard()
    }
    
    func setupCourse(_ course: Course) {
        // Setup navigation bar
        self.navigationItem.title = Constants.data.subjects[course.subject]?.uppercased()
        self.navigationItem.rightBarButtonItem = self.saveButton
        // Disable university text field
        self.universityTextField.isEnabled = false
        // Setup text fields
        self.nameTextView.text = course.name
        self.universityTextField.text = course.university
        // Setup labels
        self.subjectLabel.text = Constants.data.subjects[course.subject]
        self.subjectLabel.textColor = UIColor.black
        self.termLabel.text = course.term
        self.termLabel.textColor = UIColor.black
        // Check for description
        if let description = course.description {
            self.descriptionTextView.text = description
            self.descriptionTextView.textColor = UIColor.black
            self.tableView.reloadData()
        }
        // Check if current user is course admin
        if let currentUser = UserController.shared.currentUser, course.admin == currentUser.identifier! {
            // Enable name text field
            self.nameTextView.isEditable = true
            // Enable description text view
            self.descriptionTextView.isEditable = true
            // Add cell accessory views
            self.subjectCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
            self.termCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
            self.inviteCell.accessoryView = UIImageView(image: UIImage(named: "right.png"))
            self.assignmentsCell.accessoryView = UIImageView(image: UIImage(named: "right.png"))
            self.adminCell.accessoryView = UIImageView(image: UIImage(named: "right.png"))
        } else {
            // Disable name text field
            self.nameTextView.isEditable = false
            // Disable description text view
            self.descriptionTextView.isEditable = false
            // Remove cell accessory views
            self.subjectCell.accessoryView = nil
            self.termCell.accessoryView = nil
            self.inviteCell.accessoryView = nil
            self.assignmentsCell.accessoryView = nil
            self.adminCell.accessoryView = nil
        }
        // Fetch course users
        CourseController.usersForCourse(course) { (users) in
            if let users = users {
                var usersNameString = String()
                for user in users {
                    if user == users.last {
                        usersNameString += ("\(user.name).")
                    } else {
                        usersNameString += ("\(user.name), ")
                    }
                }
                self.memberLabel.text = usersNameString
                self.memberLabel.textColor = UIColor.black
                self.tableView.reloadData()
                if users.contains(UserController.shared.currentUser) {
                    if course.admin != UserController.shared.currentUser!.identifier! {
                        // Setup done button
                        let doneButton = UIBarButtonItem(title: "DONE", style: .plain, target: self, action: #selector(self.cancelButtonPressed))
                        doneButton.tintColor = UIColor.white
                        self.navigationItem.rightBarButtonItem = doneButton
                    }
                } else {
                    // Setup join button
                    let joinButton = UIBarButtonItem(title: "JOIN", style: .plain, target: self, action: #selector(self.joinCourse))
                    joinButton.tintColor = UIColor.white
                    self.navigationItem.rightBarButtonItem = joinButton
                }
            }
        }
        // Fetch course assignments
        AssignmentController.assignmentsForCourse(course) { (assignments) in
            if let assignments = assignments {
                var assignmentsNameString = String()
                for assignment in assignments {
                    if assignment == assignments.last {
                        assignmentsNameString += ("\(assignment.name).")
                    } else {
                        assignmentsNameString += ("\(assignment.name), ")
                    }
                }
                self.assignmentLabel.text = assignmentsNameString
                self.assignmentLabel.textColor = UIColor.black
                self.tableView.reloadData()
            }
        }
        // Setup admin label
        UserController.userWithIdentifier(course.admin) { (user) in
            if let user = user {
                self.adminLabel.text = user.name
                self.adminLabel.textColor = UIColor.black
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - SearchTextField Methods
    
    func dataForPopoverInTextField(_ textfield: SearchTextField) -> [NSDictionary] {
        return Constants.data.universityData
    }
    
    func textFieldShouldSelect(_ textField: SearchTextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - TextView Methods
    
    func textViewDidChange(_ textView: UITextView) {
        if let fieldTextView = textView as? FieldTextView {
            fieldTextView.placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespaces).isEmpty
        } else if let placeholderTextView = textView as? PlaceholderTextView {
            placeholderTextView.placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let fieldTextView = textView as? FieldTextView {
            if text == "\n" {
                fieldTextView.resignFirstResponder()
                return false
            }
        }
        return true
    }
    
    // MARK: - Navigation
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: AnyObject) {
        if let course = self.course, let currentUser = UserController.shared.currentUser, course.admin == currentUser.identifier! {
            if let name = self.nameTextView.text, !(name.trimmingCharacters(in: .whitespaces).isEmpty), let subject = self.subjectLabel.text, let term = self.termLabel.text {
                var updatedCourse = course
                updatedCourse.name = name
                updatedCourse.subject = (Constants.data.subjects as NSDictionary).allKeys(for: subject)[0] as! Int
                updatedCourse.term = term
                updatedCourse.description = nil
                if !(self.descriptionTextView.text.trimmingCharacters(in: .whitespaces).isEmpty) {
                    updatedCourse.description = self.descriptionTextView.text!
                }
                updatedCourse.save()
                self.dismiss(animated: true, completion: nil)
            } else {
                self.displayAlert("Oops!", message: "Please complete the course's profile before saving it.")
            }
        } else if self.course == nil {
            self.createCourse()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "users" {
            let searchVC = segue.destination as! SearchTableViewController
            searchVC.delegate = self
            searchVC.searchType = 0
        }
        if segue.identifier == "assignment" {
            let assignmentVc = segue.destination as! AssignmentTableViewController
            assignmentVc.course = self.course
            assignmentVc.addingToCourse = true
        }
    }
    
    // MARK: - Course Data Methods
    
    func createCourse() {
        if let currentUser = UserController.shared.currentUser, let name = self.nameTextView.text, !(name.trimmingCharacters(in: .whitespaces).isEmpty), let university = self.universityTextField.text, let subject = self.subjectLabel.text, let term = self.termLabel.text, self.subjectLabel.textColor == UIColor.black, self.termLabel.textColor == UIColor.black {
            var course = Course(name: name,
                                description: nil,
                                university: university,
                                term: term,
                                subject: (Constants.data.subjects as NSDictionary).allKeys(for: subject)[0] as! Int,
                                admin: currentUser.identifier!,
                                identifier: nil)
            if !(self.descriptionTextView.text.trimmingCharacters(in: .whitespaces).isEmpty) {
                course.description = self.descriptionTextView.text!
            }
            
            CourseController.createCourse(course, completion: { (course) in
                if let course = course {
                    self.course = course
                    self.setupCourse(course)
                } else {
                    self.displayAlert("Oops!", message: "There was a problem creating the course. Please try again.")
                }
            })
        } else {
            self.displayAlert("Oops!", message: "Please complete the course's profile before creating it.")
        }
    }
    
    func joinCourse() {
        if let currentUser = UserController.shared.currentUser, let course = self.course {
            CourseController.addUserToCourse(currentUser, course: course, completion: { (success) in
                if success {
                    CourseController.courseWithIdentifier(course.identifier!, completion: { (fetchedCourse) in
                        if let fetchedCourse = fetchedCourse {
                            self.setupCourse(fetchedCourse)
                            self.displayAlert("Congratulations!", message: "You are now a member of \(course.name).")
                        } else {
                            self.displayAlert("Oops!", message: "There was a problem joining the course. Please try again.")
                        }
                    })
                } else {
                    self.displayAlert("Oops!", message: "There was a problem joining the course. Please try again.")
                }
            })
        }
    }
    
    func leaveCourse() {
        if let currentUser = UserController.shared.currentUser, let course = self.course {
            CourseController.removeUserFromCourse(currentUser, course: course, completion: { (success) in
                if success {
                    CourseController.courseWithIdentifier(course.identifier!, completion: { (fetchedCourse) in
                        if let fetchedCourse = fetchedCourse {
                            self.setupCourse(fetchedCourse)
                            self.displayAlert("Done!", message: "You left \(course.name).")
                        } else {
                            self.displayAlert("Oops!", message: "There was a problem leaving the course. Please try again.")
                        }
                    })
                } else {
                    self.displayAlert("Oops!", message: "There was a problem leaving the course. Please try again.")
                }
            })
        }
    }
    
    func changeAdmin(to user: User) {
        if let course = self.course {
            AssignmentController.assignmentsForCourse(course, completion: { (assignments) in
                if let assignments = assignments {
                    for assignment in assignments {
                        var updatedAssignment = assignment
                        updatedAssignment.admin = user.identifier!
                        updatedAssignment.save()
                    }
                }
            })
            var updatedCourse = course
            updatedCourse.admin = user.identifier!
            updatedCourse.save()
            CourseController.courseWithIdentifier(updatedCourse.identifier!, completion: { (course) in
                if let course = course {
                    self.setupCourse(course)
                } else {
                    self.displayAlert("Oops!", message: "An error occurred. Please try again.")
                }
            })
        }
    }
    
    // MARK: - Picker View Methods
    
    func showSubjectPicker() {
        if self.termPickerVisible! {
            self.hidePickerCell(containingPicker: self.termPickerView)
        }
        if self.subjectPickerVisible! {
            self.hidePickerCell(containingPicker: self.subjectPickerView)
        } else {
            self.showPickerCell(containingPicker: self.subjectPickerView)
        }
    }
    
    func showTermPicker() {
        if self.subjectPickerVisible! {
            self.hidePickerCell(containingPicker: self.subjectPickerView)
        }
        if self.termPickerVisible! {
            self.hidePickerCell(containingPicker: self.termPickerView)
        } else {
            let currentSeason = Constants.data.seasons[0]
            let currentYear = Constants.data.years[0]
            self.termLabel.text = "\(currentSeason) \(currentYear)"
            self.termLabel.textColor = UIColor.black
            self.termPickerView.selectRow(0, inComponent: 0, animated: true)
            self.termPickerView.selectRow(0, inComponent: 1, animated: true)
            self.showPickerCell(containingPicker: self.termPickerView)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == self.termPickerView {
            return 2
        } else {
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == self.termPickerView && component == 0 {
            return 3
        } else if pickerView == self.termPickerView && component == 1 {
            return Constants.data.years.count
        } else {
            return Constants.data.subjects.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == self.termPickerView && component == 0 {
            return Constants.data.seasons[row]
        } else if pickerView == self.termPickerView && component == 1 {
            return Constants.data.years[row]
        } else {
            return Constants.data.subjects[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == self.termPickerView {
            var termComponents = self.termLabel.text!.components(separatedBy: " ")
            if component == 0 {
                termComponents[0] = Constants.data.seasons[row]
            }
            if component == 1 {
                termComponents[1] = Constants.data.years[row]
            }
            let term = "\(termComponents[0]) \(termComponents[1])"
            self.termLabel.text = term
        } else {
            let subject = Constants.data.subjects[row]
            self.subjectLabel.text = subject
            self.subjectLabel.textColor = UIColor.black
        }
    }
    
    func showPickerCell(containingPicker picker:UIPickerView) {
        if picker == self.subjectPickerView {
            self.subjectPickerVisible = true
            self.subjectCell.accessoryView = UIImageView(image: UIImage(named: "up.png"))
        } else if picker == self.termPickerView {
            self.termPickerVisible = true
            self.termCell.accessoryView = UIImageView(image: UIImage(named: "up.png"))
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
        picker.isHidden = false
        picker.alpha = 0.0
        
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            picker.alpha = 1.0
        })
    }
    
    func hidePickerCell(containingPicker picker:UIPickerView) {
        if picker == self.subjectPickerView {
            self.subjectPickerVisible = false
            self.subjectCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
        } else if picker == self.termPickerView {
            self.termPickerVisible = false
            self.termCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
        UIView.animate(withDuration: 0.25,
                                   animations: { () -> Void in
                                    picker.alpha = 0.0
            },
                                   completion:{ (finished) -> Void in
                                    picker.isHidden = true
            }
        )
    }
    
    // MARK: Table View Data Source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height:CGFloat = 60
        switch indexPath.row {
        case 2:
            // Description row
            if !(self.descriptionTextView.text.trimmingCharacters(in: .whitespaces).isEmpty) {
                let estimatedSize = CGSize(width: tableView.frame.size.width - 16, height: 1000)
                let font = self.descriptionTextView.font!
                let estimatedFrame = self.descriptionTextView.text.estimateFrame(for: estimatedSize, with: font)
                height = estimatedFrame.size.height + 40
            } else {
                height = 80
            }
        case 4:
            // Subject picker row
            if let subjectPickerVisible = self.subjectPickerVisible {
                height = subjectPickerVisible ? 216 : 0
            }
        case 6:
            // Term picker row
            if let termPickerVisible = self.termPickerVisible {
                height = termPickerVisible ? 216 : 0
            }
        case 7:
            // People row
            if self.course != nil && self.memberLabel.requiredHeight() > 40 {
                height = self.memberLabel.requiredHeight() + 20
            }
        case 8:
            // Assignments row
            if self.course != nil && self.assignmentLabel.requiredHeight() > 40 {
                height = self.assignmentLabel.requiredHeight() + 20
            }
        case 9:
            // Admin row
            if self.course == nil {
                height = 0
            }
        default:
            break
        }
        return height
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismissKeyboard()
        switch indexPath.row {
        case 3:
            // Subject row
            if let course = self.course, let currentUser = UserController.shared.currentUser, course.admin == currentUser.identifier! {
                self.showSubjectPicker()
            } else if self.course == nil {
                self.showSubjectPicker()
            }
            
        case 5:
            // Term row
            if let course = self.course, let currentUser = UserController.shared.currentUser, course.admin == currentUser.identifier! || self.course == nil {
                self.showTermPicker()
            } else if self.course == nil {
                self.showTermPicker()
            }
        
        case 7:
            // People row
            if let course = self.course, let currentUser = UserController.shared.currentUser {
                if course.admin == currentUser.identifier! {
                    self.userSelectionType = 0
                    self.performSegue(withIdentifier: "users", sender: self)
                }
            } else {
                self.displayAlert("Almost there!", message: "Once you create the course you can add people.")
            }
        case 8:
            // Assignment row
            if let course = self.course, let currentUser = UserController.shared.currentUser {
                if course.admin == currentUser.identifier! {
                    self.performSegue(withIdentifier: "assignment", sender: self)
                }
            } else {
                self.displayAlert("Almost there!", message: "Once you create the course you can create new assignments.")
            }
        case 9:
            // Admin row
            if let course = self.course, let currentUser = UserController.shared.currentUser, course.admin == currentUser.identifier! {
                let alert = UIAlertController(title: "Warning!", message: "After selecting a new administrator, you will lose your management priviledges for the course and any assignments linked to it.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    self.userSelectionType = 1
                    self.performSegue(withIdentifier: "users", sender: self)
                }))
                alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                alert.view.tintColor = Constants.data.lightBlue
            }
        default:
            break
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension CourseTableViewController : SearchDelegate {
    
    func resultSelected(_ result: Any) {
        if let user = result as? User {
            print("selected: \(user.name)")
            self.actionFor(user: user)
        }
    }
    
    func actionFor(user: User) {
        if let currentUser = UserController.shared.currentUser, let course = self.course, course.admin == currentUser.identifier! {
            if let selectionType = self.userSelectionType {
                if selectionType == 0 {
                    CourseController.addUserToCourse(user, course: course, completion: { (success) in
                        if success {
                            self.setupCourse(course)
                        } else {
                            self.displayAlert("Invite Failed", message: "Please try again.")
                        }
                    })
                } else if selectionType == 1 {
                    let alert = UIAlertController(title: "Are you sure?", message: "After this point, \(user.firstName()) will have control over the course and any assignments linked to it.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "CONFIRM", style: .destructive, handler: { (alert) in
                        self.changeAdmin(to: user)
                    }))
                    alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    alert.view.tintColor = Constants.data.lightBlue
                }
            }
        }
    }
}
