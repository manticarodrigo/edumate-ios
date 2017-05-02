//
//  ProfileViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 3/2/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import Photos

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, SearchTextFieldDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate {
    
    var user: User?
    var courses: [Course]?
    var tutored: [Bool]?
    
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var universityTextField: SearchTextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var courseTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Layout subviews
        self.view.layoutIfNeeded()
        // Setup navBar
        self.stylizeNavBar()
        self.navigationController?.navigationBar.addDropShadow()
        self.navigationItem.title = nil
        // Setup card view
        self.cardView.layer.cornerRadius = 10
        self.cardView.addDropShadow()
        // Setup image view
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height/2
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showPhotoOptions))
        tapGestureRecognizer.cancelsTouchesInView = false
        self.imageView.addGestureRecognizer(tapGestureRecognizer)
        // Setup name field
        self.nameTextField.delegate = self
        // Setup university field
        self.universityTextField.delegate = self
        self.universityTextField.searchDelegate = self
        // Setup dynamic tableview row heights
        self.courseTableView.estimatedRowHeight = 160
        self.courseTableView.rowHeight = UITableViewAutomaticDimension
        self.courseTableView.setNeedsLayout()
        self.courseTableView.layoutIfNeeded()
        // Remove empty table view cells
        self.courseTableView.tableFooterView = UIView()
        // Setup user profile
        self.updateViewBasedOnUser()
        // Add gesture to hide keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateUserProfile()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissKeyboard()
    }
    
    // MARK: - User Methods
    
    func updateViewBasedOnUser() {
        if let currentUser = UserController.shared.currentUser {
            if let user = self.user, user != currentUser {
                // Disable Input
                self.nameTextField.isEnabled = false
                self.universityTextField.isEnabled = false
                self.imageView.isUserInteractionEnabled = false
                // Setup navBar back button
                let clearButton = UIBarButtonItem(image: UIImage(named: "clear.png"), style: .plain, target: self, action: #selector(clearButtonPressed))
                self.navigationItem.leftBarButtonItem = clearButton
                // Setup navBar add button
                UserController.userFollows(UserController.shared.currentUser, followsUser: user) { (follows) -> Void in
                    if follows {
                        // User has been saved
                        self.actionButton.image = UIImage(named: "remove.png")
                    } else {
                        // User has not been saved
                        self.actionButton.image = UIImage(named: "check.png")
                    }
                }
            } else {
                self.user = currentUser
            }
        } else {
            self.tabBarController?.performSegue(withIdentifier: "login", sender:nil)
        }
        self.updateUserProfile()
    }
    
    func updateUserProfile() {
        if let user = self.user {
            // Load user profile
            self.nameTextField.text = user.name
            if let university = user.university {
                self.universityTextField.text = university
            } else {
                if let currentUser = UserController.shared.currentUser, user == currentUser {
                    self.universityTextField.text = nil
                } else {
                    self.universityTextField.text = " "
                }
            }
            self.imageView.loadImageWithIdentifier(user.identifier!)
            CourseController.coursesForUser(user) { (courses) in
                if let courses = courses {
                    var tutoredCourses = [Bool]()
                    for course in courses {
                        UserController.userTutors(user, subject: course.subject, completion: { (tutors) in
                            if tutors {
                                tutoredCourses.append(true)
                            } else {
                                tutoredCourses.append(false)
                            }
                            if tutoredCourses.count == courses.count {
                                self.courses = courses
                                self.tutored = tutoredCourses
                                self.courseTableView.reloadData()
                            }
                        })
                    }
                } else {
                    self.courses = nil
                    self.tutored = nil
                    self.courseTableView.reloadData()
                }
            }
        } else {
            if let currentUser = UserController.shared.currentUser {
                self.user = currentUser
                self.updateUserProfile()
            } else {
                self.tabBarController?.performSegue(withIdentifier: "login", sender:nil)
            }
        }
    }
    
    // MARK: - Navigation Button Methods
    
    func clearButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func actionButtonPressed(_ sender: AnyObject) {
        if let currentUser = UserController.shared.currentUser, let user = self.user {
            if user == currentUser {
                self.performSegue(withIdentifier: "settings", sender: self)
            } else {
                UserController.userFollows(currentUser, followsUser: user) { (follows) -> Void in
                    if follows {
                        // User has been saved
                        UserController.unfollow(user, completion: { (success) in
                            self.actionButton.image = UIImage(named: "check.png")
                            self.displayAlert("Done!", message: "You are no longer following \(user.firstName())")
                        })
                    } else {
                        // User has not been saved
                        UserController.follow(user, completion: { (success) in
                            self.actionButton.image = UIImage(named: "remove.png")
                            self.displayAlert("Success!", message: "You are now following \(user.firstName())")
                        })
                    }
                }
            }
        }
    }
    
    func tutorButtonPressed() {
        self.performSegue(withIdentifier: "subjects", sender: self)
    }
    
    // MARK: - TextField Delegate Methods
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.nameTextField {
            if !(textField.text?.trimmingCharacters(in: .whitespaces).isEmpty)! {
                if let user = self.user, let currentUser = UserController.shared.currentUser, user == currentUser {
                    var updatedUser = User(name: nameTextField.text!, university: currentUser.university ?? nil, uid: currentUser.identifier!)
                    updatedUser.save()
                    UserController.userWithIdentifier(currentUser.identifier!, completion: { (fetchedUser) -> Void in
                        if let fetchedUser = fetchedUser {
                            self.user = fetchedUser
                            UserController.shared.currentUser = fetchedUser
                        }
                    })
                }
            }
        }
        if textField == self.universityTextField {
            if let user = self.user, let currentUser = UserController.shared.currentUser, user == currentUser {
                if (textField.text?.trimmingCharacters(in: .whitespaces).isEmpty)! {
                    textField.text = nil
                }
                var updatedUser = User(name: currentUser.name, university: textField.text, uid: currentUser.identifier!)
                updatedUser.save()
                UserController.userWithIdentifier(currentUser.identifier!, completion: { (fetchedUser) -> Void in
                    if let fetchedUser = fetchedUser {
                        self.user = fetchedUser
                        UserController.shared.currentUser = fetchedUser
                    }
                })
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return true
    }
    
    // MARK: - SearchTextField Methods
    
    func dataForPopoverInTextField(_ textfield: SearchTextField) -> [NSDictionary] {
        return Constants.data.universityData
    }
    
    func textFieldShouldSelect(_ textField: SearchTextField) -> Bool {
        return false
    }
    
    // MARK: - Image View Methods
    
    func showPhotoOptions() {
        let sheet = UIAlertController(title: "PHOTO OPTIONS", message: "What would you like to do?", preferredStyle: .actionSheet)
        let frame = CGRect(x: 0, y: 0, width: self.imageView.bounds.width, height: self.imageView.bounds.height)
        sheet.popoverPresentationController?.sourceView = self.imageView
        sheet.popoverPresentationController?.sourceRect = frame
        
        let cameraAction = UIAlertAction(title: "CAMERA", style: .default) { (alert) in
            self.handleImageSelection(sourceType: .camera)
        }
        sheet.addAction(cameraAction)
        
        let libraryAction = UIAlertAction(title: "PHOTO LIBRARY", style: .default) { (alert) in
            self.handleImageSelection(sourceType: .photoLibrary)
        }
        sheet.addAction(libraryAction)
        
        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel, handler: nil)
        sheet.addAction(cancelAction)
        
        self.present(sheet, animated: true, completion: nil)
        sheet.view.tintColor = Constants.data.lightBlue
    }
    
    func handleImageSelection(sourceType: UIImagePickerControllerSourceType) {
        if sourceType == .camera {
            let cameraMediaType = AVMediaTypeVideo
            let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
            switch cameraAuthorizationStatus {
            case .authorized:
                // Handle authorized status
                self.presentImagePicker(sourceType: .camera)
            case .denied, .restricted:
                // Handle denied status
                self.displayAlert("Camera Disabled", message: "Navigate to your device's settings page and scroll down to the Edumate app to enable camera access.")
            case .notDetermined:
                // Prompt user for permission to use the camera.
                AVCaptureDevice.requestAccess(forMediaType: cameraMediaType) { granted in
                    if granted {
                        // Handle authorized status
                        self.presentImagePicker(sourceType: .camera)
                    } else {
                        // Handle denied status
                        self.displayAlert("Camera Disabled", message: "Navigate to your device's settings page and scroll down to the Edumate app to enable camera access.")
                    }
                }
            }
        } else if sourceType == .photoLibrary {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized:
                // Handle authorized status
                self.presentImagePicker(sourceType: .photoLibrary)
            case .denied, .restricted :
                // Handle denied status
                self.displayAlert("Photos Disabled", message: "Navigate to your device's settings page and scroll down to the Edumate app to enable photo access.")
            case .notDetermined:
                // Prompt user for permission to access photo library.
                PHPhotoLibrary.requestAuthorization() { status in
                    switch status {
                    case .authorized:
                        // Handle authorized status
                        self.presentImagePicker(sourceType: .photoLibrary)
                    case .denied, .restricted:
                        // Handle denied status
                        self.displayAlert("Photos Disabled", message: "Navigate to your device's settings page and scroll down to the Edumate app to enable photo access.")
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func presentImagePicker(sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = sourceType
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            self.imageView.image = editedImage
            self.uploadImage(editedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func uploadImage(_ image: UIImage) {
        if let user = self.user, let currentUser = UserController.shared.currentUser {
            if user == currentUser {
                let activityIndicator = self.imageView.addActivityIndicator()
                ImageController.uploadImageForIdentifier(currentUser.identifier!, image: image) { (image) in
                    if let image = image {
                        cache.setObject(image, forKey: currentUser.identifier! as AnyObject)
                        self.imageView.image = image
                        self.displayAlert("Image Saved", message: "Your profile image has been updated!")
                        activityIndicator.stopAnimating()
                    } else {
                        self.displayAlert("Upload Failed", message: "Please try again.")
                        activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let currentUser = UserController.shared.currentUser, let user = self.user, user == currentUser {
            self.courseTableView.backgroundView = nil
            self.courseTableView.separatorStyle = .singleLine
            return 1
        } else if self.courses != nil {
            self.courseTableView.backgroundView = nil
            self.courseTableView.separatorStyle = .singleLine
            return 1
        } else {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.courseTableView.bounds.size.width, height: self.courseTableView.bounds.size.height))
            noDataLabel.text = "NO COURSES FOUND."
            noDataLabel.textColor = UIColor.lightGray
            noDataLabel.textAlignment = .center
            self.courseTableView.separatorStyle = .none
            self.courseTableView.backgroundView = noDataLabel
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "COURSES:"
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.backgroundView?.backgroundColor = UIColor.white
        header.textLabel?.textAlignment = .left
        header.textLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightBold)
        header.textLabel?.textColor = UIColor.darkGray
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let courses = self.courses {
            return courses.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "courseCell", for: indexPath) as! ProfileCoursesTableViewCell
        if let courses = self.courses {
            let course = courses[indexPath.row]
            cell.nameLabel.textAlignment = .left
            cell.nameLabel.text = course.name
            let subject = Constants.data.subjects[course.subject]
            cell.subjectLabel.text = subject
            if let tutors = self.tutored?[indexPath.row] {
                if tutors {
                    cell.tutorLabel.isHidden = false
                } else {
                    cell.tutorLabel.isHidden = true
                }
            }
        } else if let user = self.user, let currentUser = UserController.shared.currentUser, user == currentUser {
            cell.nameLabel.text = "You have not joined any courses."
            cell.subjectLabel.text = "Tap to join or create courses."
            cell.tutorLabel.isHidden = true
        }
        return cell
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.courses != nil {
            self.performSegue(withIdentifier: "course", sender: self)
        } else {
            self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers![2]
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "course" {
            if let indexPath = self.courseTableView.indexPathForSelectedRow {
                let nav = segue.destination as! UINavigationController
                let courseVc = nav.topViewController as! CourseTableViewController
                courseVc.course = self.courses![indexPath.row]
            }
        }
        if segue.identifier == "subjects" {
            if let user = self.user {
                let nav = segue.destination as! UINavigationController
                let subjectsVc = nav.topViewController as! SubjectsTableViewController
                subjectsVc.user = user
            }
        }
    }
    
}
