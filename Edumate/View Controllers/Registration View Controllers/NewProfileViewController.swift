//
//  NewProfileViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/28/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import Photos

class NewProfileViewController: UIViewController, UITextFieldDelegate, SearchTextFieldDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var universityTextField: SearchTextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Layout subviews
        self.view.layoutIfNeeded()
        // Setup card view
        self.cardView.layer.cornerRadius = 10
        self.cardView.addDropShadow()
        // Setup name text field
        self.nameTextField.delegate = self
        // Setup university text field
        self.universityTextField.delegate = self
        self.universityTextField.searchDelegate = self
        // Setup image view
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height/2
        // Add gesture recognizer to image view
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(handleImageSelection))
        tapGestureRecognizer.cancelsTouchesInView = false
        self.imageView.addGestureRecognizer(tapGestureRecognizer)
        // Setup create button
        self.createButton.stylize()
        // Retrieve facebook data
        if let currentUser = FirebaseController.auth!.currentUser {
            for profile in (currentUser.providerData) {
                // Check if provider contains name and image
                let uid = profile.uid
                let name = profile.displayName
                if name != nil && uid.isEmpty != true {
                    // Get NSData from the image
                    let urlString = "https://graph.facebook.com/\(uid)/picture?type=large"
                    let url = URL(string: urlString)
                    let data = try? Data(contentsOf: url!)
                    let image = UIImage(data: data!)
                    // Load user's name and image
                    self.nameTextField.text = name
                    self.imageView.image = image
                }
            }
        } else {
            self.cancelButtonPressed(self)
        }
        // Add gesture to hide keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    // MARK: - Navigation
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        UserController.logoutCurrentUser()
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITextField Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - SearchTextField Delegate
    
    func dataForPopoverInTextField(_ textfield: SearchTextField) -> [NSDictionary] {
        return Constants.data.universityData
    }
    
    func textFieldShouldSelect(_ textField: SearchTextField) -> Bool {
        return true
    }
    
    // MARK: - Image View Delegate
    
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
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Account Data Methods
    
    @IBAction func createButtonPressed(_ sender: AnyObject) {
        if let name = self.nameTextField.text, let image = self.imageView.image {
            if !(name.trimmingCharacters(in: .whitespaces).isEmpty) && image != UIImage(named: "user-placeholder.png") {
                if let currentUser = FirebaseController.auth?.currentUser {
                    ImageController.uploadImageForIdentifier(currentUser.uid, image: image, completion: { (image) in
                        if image != nil {
                            let university = self.universityTextField.text
                            var user = User(name: name, university: university, uid: currentUser.uid)
                            user.save()
                            UserController.userWithIdentifier(currentUser.uid, completion: { (user) -> Void in
                                if let currentUser = user {
                                    print("\(currentUser.name) is the current user.")
                                    UserController.shared.currentUser = currentUser
                                    self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
                                } else {
                                    self.displayAlert("Oops!", message: "There was a problem creating the account. Please try again.")
                                }
                            })
                        } else {
                            self.displayAlert("Oops!", message: "There was a problem uploading your image. Please try again.")
                        }
                    })
                }
            } else {
                self.displayAlert("Oops!", message: "Please complete your profile including your full name and a profile image.")
            }
        } else {
            self.displayAlert("Oops!", message: "Please complete your profile including your full name and a profile image.")
        }
    }
    
}
