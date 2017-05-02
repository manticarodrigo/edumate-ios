//
//  AssignmentTableViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/31/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class AssignmentTableViewController: UITableViewController, UITextViewDelegate {
    
    var assignment: Assignment?
    var dueDate: Date?
    var course: Course?
    
    @IBOutlet weak var dueDateCell: UITableViewCell!
    @IBOutlet weak var courseCell: UITableViewCell!
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameTextView: FieldTextView!
    @IBOutlet weak var descriptionTextView: PlaceholderTextView!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var courseLabel: UILabel!
    
    var dueDatePickerVisible: Bool?
    var addingToCourse: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup navBar
        self.stylizeNavBar()
        // Setup name text field
        self.nameTextView.delegate = self
        self.nameTextView.text = nil
        self.nameTextView.placeholder = "Enter assignment name"
        // Setup description text view
        self.descriptionTextView.delegate = self
        self.descriptionTextView.text = nil
        self.descriptionTextView.placeholder = "Add description"
        // Remove empty cells
        self.tableView.tableFooterView = UIView()
        // Add gesture to dismiss keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Setup due date label
        if let dueDate = self.dueDate {
            self.dueDateLabel.text = dueDate.monthDayYearHour()
            self.dueDatePicker.date = dueDate
        }
        // Setup due date picker
        self.dueDatePickerVisible = false
        self.dueDatePicker.isHidden = true
        // Setup assignment
        if let assignment = self.assignment {
            self.setupAssignment(assignment)
        } else {
            if let course = self.course {
                self.courseLabel.text = course.name
                if let addingToCourse = self.addingToCourse {
                    if addingToCourse {
                        let backButton = UIBarButtonItem(image: UIImage(named: "left.png"), style: .plain, target: self, action: #selector(backButtonPressed))
                        backButton.tintColor = UIColor.white
                        self.navigationItem.leftBarButtonItem = backButton
                    }
                }
            }
            let createButton = UIBarButtonItem(title: "CREATE", style: .plain, target: self, action: #selector(createAssignment))
            createButton.tintColor = UIColor.white
            self.navigationItem.rightBarButtonItem = createButton
            self.nameTextView.isEditable = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Dismiss keyboard
        self.dismissKeyboard()
    }
    
    func setupAssignment(_ assignment: Assignment) {
        // Add all text to fields
        self.nameTextView.text = assignment.name
        if let description = assignment.description {
            self.descriptionTextView.text = description
            self.descriptionTextView.textColor = UIColor.black
        }
        let dueDate:Date = Date(timeIntervalSince1970: TimeInterval(assignment.dueDate))
        self.dueDate = dueDate
        self.dueDateLabel.text = dueDate.monthDayYearHour()
        self.dueDateLabel.textColor = UIColor.black
        // Check if current user is assignment admin
        if let currentUser = UserController.shared.currentUser, currentUser.identifier! == assignment.admin {
            // Enable name text view
            self.nameTextView.isEditable = true
            // Enable description text view
            self.descriptionTextView.isEditable = true
            // Setup save button
            self.navigationItem.rightBarButtonItem = self.saveButton
            // Add cell accessory views
            self.dueDateCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
            self.courseCell.accessoryView = UIImageView(image: UIImage(named: "right.png"))
        } else {
            // Disable name text view
            self.nameTextView.isEditable = false
            // Disable description text view
            self.descriptionTextView.isEditable = false
            // Setup done button
            let doneButton = UIBarButtonItem(title: "DONE", style: .plain, target: self, action: #selector(cancelButtonPressed))
            doneButton.tintColor = UIColor.white
            self.navigationItem.rightBarButtonItem = doneButton
            // Remove cell accessory views
            self.dueDateCell.accessoryView = nil
            self.courseCell.accessoryView = nil
        }
        // Fetch assignment course
        AssignmentController.courseForAssignment(assignment, completion: { (course) in
            if let course = course {
                self.course = course
                self.navigationItem.title = Constants.data.subjects[course.subject]?.uppercased()
                self.courseLabel.text = course.name
                self.courseLabel.textColor = UIColor.black
            } else if let course = self.course {
                self.course = course
                self.navigationItem.title = Constants.data.subjects[course.subject]?.uppercased()
                self.courseLabel.text = course.name
                self.courseLabel.textColor = UIColor.black
            } else {
                self.navigationItem.title = "MANAGE ASSIGNMENT"
            }
        })
    }
    
    // MARK: - TextView Delegate Methods
    
    func textViewDidChange(_ textView: UITextView) {
        if let fieldTextView = textView as? FieldTextView {
            fieldTextView.placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespaces).isEmpty
        } else if let placeholderTextView = textView as? PlaceholderTextView {
            placeholderTextView.placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == self.nameTextView, text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Navigation
    
    func backButtonPressed() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: AnyObject) {
        if let assignment = self.assignment, let currentUser = UserController.shared.currentUser, assignment.admin == currentUser.identifier! {
            if let name = self.nameTextView.text, let dueDate = self.dueDate, !(name.trimmingCharacters(in: .whitespaces).isEmpty) {
                var updatedAssignment = assignment
                updatedAssignment.name = name
                if self.descriptionTextView.text.trimmingCharacters(in: .whitespaces).isEmpty {
                    updatedAssignment.description = nil
                } else {
                    updatedAssignment.description = self.descriptionTextView.text!
                }
                updatedAssignment.dueDate = NSNumber(integerLiteral: Int(dueDate.timeIntervalSince1970))
                if let course = self.course {
                    CourseController.addAssignmentToCourse(assignment, course: course, completion: { (success) in
                        if success {
                            updatedAssignment.course = course.identifier!
                        } else {
                            self.displayAlert("Oops!", message: "Could not add assignment to \(course.name). Please try again.")
                        }
                    })
                }
                updatedAssignment.save()
                self.dismiss(animated: true, completion: nil)
            } else {
                self.displayAlert("Oops!", message: "Please add a name and due date before saving your assignment.")
            }
        } else if self.assignment == nil {
            self.createAssignment()
        }
    }
    
    // MARK: - Assignment Data Methods
    
    func createAssignment() {
        if let currentUser = UserController.shared.currentUser, let name = self.nameTextView.text, let dueDate = self.dueDate, !(name.trimmingCharacters(in: .whitespaces).isEmpty) {
            var assignment = Assignment(name: name,
                                        description: self.descriptionTextView.text,
                                        dueDate: NSNumber(integerLiteral: Int(dueDate.timeIntervalSince1970)),
                                        admin: currentUser.identifier!,
                                        course: self.course?.identifier!,
                                        identifier: nil)
            if let course = self.course {
                CourseController.addAssignmentToCourse(assignment, course: course, completion: { (success) in
                    if success {
                        assignment.save()
                        self.assignment = assignment
                        self.setupAssignment(assignment)
                    } else {
                        self.displayAlert("Oops!", message: "Could not add assignment to \(course.name). Please try again.")
                    }
                })
            } else {
                assignment.save()
                self.assignment = assignment
                self.setupAssignment(assignment)
            }
        } else {
            self.displayAlert("Oops!", message: "Please add a name and due date before creating an assignment.")
        }
    }
    
    func deleteAssignment(assignment: Assignment) {
        if let course = self.course {
            CourseController.removeAssignmentFromCourse(assignment, course: course, completion: { (success) in
                if success {
                    let updatedAssignment = assignment
                    updatedAssignment.delete()
                    AssignmentController.assignmentWithIdentifier(updatedAssignment.identifier!, completion: { (assignment) in
                        if assignment == updatedAssignment {
                            self.displayAlert("Oops!", message: "An error occurred. Please try again.")
                        } else {
                            self.cancelButtonPressed(self)
                        }
                    })
                } else {
                    self.displayAlert("Oops!", message: "An error occurred. Please try again.")
                }
            })
        } else {
            let updatedAssignment = assignment
            updatedAssignment.delete()
            AssignmentController.assignmentWithIdentifier(updatedAssignment.identifier!, completion: { (assignment) in
                if assignment == updatedAssignment {
                    self.displayAlert("Oops!", message: "An error occurred. Please try again.")
                } else {
                    self.cancelButtonPressed(self)
                }
            })
        }
    }
    
    // MARK: Date Picker Methods
    
    func showDueDatePicker() {
        if self.dueDatePickerVisible! {
            self.hidePickerCell()
        } else {
            self.showPickerCell()
            let date = Date()
            self.dueDate = date
            let dateString = date.monthDayYearHour()
            self.dueDateLabel.text = dateString
            self.dueDateLabel.textColor = UIColor.black
            self.dueDatePicker.setDate(date, animated: true)
        }
    }
    
    @IBAction func dueDateChanged(_ sender: AnyObject) {
        guard let picker = sender as? UIDatePicker else {
            return
        }
        self.dueDate = picker.date
        let dateString = picker.date.monthDayYearHour()
        self.dueDateLabel.text = dateString
        self.dueDateLabel.textColor = UIColor.black
    }
    
    func showPickerCell() {
        self.dueDateCell.accessoryView = UIImageView(image: UIImage(named: "up.png"))
        self.dueDatePickerVisible = true
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        self.dueDatePicker.isHidden = false
        self.dueDatePicker.alpha = 0
        UIView.animate(withDuration: 0.25, animations: {
            self.dueDatePicker.alpha = 1
        })
    }
    
    func hidePickerCell() {
        self.dueDateCell.accessoryView = UIImageView(image: UIImage(named: "down.png"))
        self.dueDatePickerVisible = false
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        UIView.animate(withDuration: 0.25, animations: {
            self.dueDatePicker.alpha = 0
        }, completion: { (finished) in
            self.dueDatePicker.isHidden = true
        })
    }
    
    // MARK: Table View Data Source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height:CGFloat = 60
        if indexPath.row == 1 {
            // Description row
            if !(self.descriptionTextView.text.trimmingCharacters(in: .whitespaces).isEmpty) {
                let estimatedSize = CGSize(width: tableView.frame.size.width - 16, height: 1000)
                let font = self.descriptionTextView.font!
                let estimatedFrame = self.descriptionTextView.text.estimateFrame(for: estimatedSize, with: font)
                height = estimatedFrame.size.height + 40
            } else {
                height = 80
            }
        }
        if indexPath.row == 3 {
            // Due date picker row
            if let pickerVisible = self.dueDatePickerVisible {
                height = pickerVisible ? 216 : 0
            }
        }
        if indexPath.row == 5 {
            // Delete row
            if let assignment = self.assignment, let currentUser = UserController.shared.currentUser, assignment.admin != currentUser.identifier! {
                height = 0
            } else if self.assignment == nil {
                height = 0
            }
        }
        return height
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let assignment = self.assignment, let currentUser = UserController.shared.currentUser, assignment.admin == currentUser.identifier! {
            // Due date row
            if indexPath.row == 2 {
                self.showDueDatePicker()
            }
            // Course row
            if indexPath.row == 4 {
                self.performSegue(withIdentifier: "courses", sender: self)
            }
            // Delete row
            if indexPath.row == 5 {
                let alert = UIAlertController(title: "Are you sure?", message: "You are about to delete this assignment.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "DELETE", style: .destructive, handler: { (alert) in
                    self.deleteAssignment(assignment: assignment)
                }))
                alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                alert.view.tintColor = Constants.data.lightBlue
            }
        } else if self.assignment == nil {
            // Due date row
            if indexPath.row == 2 {
                self.showDueDatePicker()
            }
            // Course row
            if indexPath.row == 4 {
                self.performSegue(withIdentifier: "courses", sender: self)
            }
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "courses" {
            let searchVC = segue.destination as! SearchTableViewController
            searchVC.delegate = self
            searchVC.searchType = 1
        }
    }

}

extension AssignmentTableViewController : SearchDelegate {
    
    func resultSelected(_ result: Any) {
        if let course = result as? Course {
            print("selected: \(course.name)")
            if course.admin != UserController.shared.currentUser.identifier! {
                self.displayAlert("Oops!", message: "You must be the course administrator to add assignments.")
            } else {
                self.course = course
                self.courseLabel.text = course.name
                self.courseLabel.textColor = UIColor.black
            }
        }
    }
    
}
