//
//  LoginViewController.swift
//  Edumate
//
//  Created by Labuser  on 5/13/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var segmentedControl: StyledSegmentedControl!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    
    var activityIndicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup input container view
        self.inputContainerView.layer.cornerRadius = 10
        self.inputContainerView.clipsToBounds = true
        // Setup text fields
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        // Setup buttons
        self.emailButton.stylize()
        self.facebookButton.stylize()
        // Setup segmented control
        self.segmentedControl.addTarget(self, action: #selector(self.segmentedValueChanged), for: .valueChanged)
        // Add gesture to hide keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logOut()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SearchController.stopObservingUsers()
        SearchController.observeUsers()
    }
    
    func startActivityIndicator() {
        self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        self.activityIndicator.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    // MARK: - UITextField Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if !(self.emailTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty)! && !(self.passwordTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty)! {
            self.emailButtonPressed(self)
        } else if textField == self.emailTextField {
            self.passwordTextField.becomeFirstResponder()
        }
        return true
    }
    
    // MARK: - UIButton Methods
    
    func segmentedValueChanged() {
        if self.segmentedControl.selectedIndex == 0 {
            self.emailButton.setTitle("LOGIN", for: UIControlState())
        } else {
            self.emailButton.setTitle("REGISTER", for: UIControlState())
        }
    }
    
    @IBAction func emailButtonPressed(_ sender: AnyObject) {
        if self.emailTextField.text!.isEmpty || self.passwordTextField.text!.isEmpty {
            self.displayAlert("Oops!", message: "Please enter a valid email and password.")
        } else {
            if self.segmentedControl.selectedIndex == 0 {
                self.loginWithEmail()
            } else {
                self.registerWithEmail()
            }
        }
    }
    
    // MARK: - Email Authentication
    
    func loginWithEmail() {
        self.startActivityIndicator()
        let email = self.emailTextField.text!
        let password = self.passwordTextField.text!
        UserController.authenticateUserWithEmail(email, password: password, completion: { (message, user) in
            self.activityIndicator.stopAnimating()
            if message != nil {
                self.displayAlert("Login Failed", message: message!)
            } else {
                self.verifyEmail()
            }
        })
    }
    
    func registerWithEmail() {
        self.startActivityIndicator()
        let email = self.emailTextField.text!
        let password = self.passwordTextField.text!
        FirebaseController.auth?.createUser(withEmail: email, password: password) { (response, error) -> Void in
            self.activityIndicator.stopAnimating()
            if let uid = response?.uid {
                print("\(uid) created successfully.")
                self.verifyEmail()
            } else {
                FirebaseController.errorMessageForCode(error! as NSError, completion: { (message) in
                    self.displayAlert("Registration Failed", message: message!)
                })
            }
        }
    }
    
    // MARK: Facebook Authentication
    
    @IBAction func facebookButtonPressed(_ sender: AnyObject) {
        self.startActivityIndicator()
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["public_profile", "email", "user_friends"], from: self) { (result, error) -> Void in
            self.activityIndicator.stopAnimating()
            if error != nil {
                self.displayAlert("Login Failed", message: "There was a problem logging in to your Facebook account. Please try again.")
                return
            } else if result?.isCancelled == true {
                self.displayAlert("Oops!", message: "You cancelled the authentication process.")
            } else {
                UserController.authenticateUserWithToken(FBSDKAccessToken.current().tokenString, completion: { (success, user) in
                    if success == false {
                        self.displayAlert("Login Failed", message: "There was a problem logging in to your Edumate account. Please try again.")
                    } else {
                        self.finishAuthentication()
                    }
                })
            }
        }
    }
    
    // MARK: - Email Verification
    
    func verifyEmail() {
        if let currentUser = FirebaseController.auth?.currentUser {
            if currentUser.isEmailVerified {
                self.finishAuthentication()
            } else {
                let alertController = UIAlertController(title: "Verification Required", message: "Please press 'SEND' to receive a verification email before logging in.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel, handler: nil)
                let sendAction = UIAlertAction(title: "SEND", style: .destructive) { (_) -> Void in
                    currentUser.sendEmailVerification() { error in
                        if let error = error {
                            // An error happened.
                            print(error)
                            self.displayAlert("Oops!", message: "An error occurred. Please try again.")
                        } else {
                            // Email sent.
                            self.displayAlert("Success!", message: "We sent you a verification email.")
                        }
                    }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(sendAction)
                self.present(alertController, animated: true, completion: nil)
                alertController.view.tintColor = Constants.data.lightBlue
            }
        }
    }
    
    // MARK: - Navigation
    
    func finishAuthentication() {
        if UserController.shared.currentUser != nil {
            OneSignalController.devicePushToken(completion: { (token) in
                if let token = token {
                    UserController.setPushToken(token)
                } else {
                    UserController.setPushToken(nil)
                }
            })
            self.dismiss(animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "register", sender: self)
        }
    }
    
    // MARK: - Password Reset
    
    @IBAction func resetPasswordPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Reset Password", message: "We will send you password reset instructions to the email provided below.", preferredStyle: .alert)
        alertController.addTextField { (emailField) in
            emailField.placeholder = "Email"
        }
        let emailField = alertController.textFields![0]
        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel, handler: nil)
        let submitAction = UIAlertAction(title: "SUBMIT", style: .default) { (_) -> Void in
            if emailField.text?.trimmingCharacters(in: .whitespaces).isEmpty == false {
                FirebaseController.auth?.sendPasswordReset(withEmail: emailField.text!) { error in
                    if let error = error {
                        // An error happened.
                        print(error)
                        self.displayAlert("Oops!", message: "An error occurred. Please try again later.")
                    } else {
                        // Password reset email sent.
                        self.displayAlert("Success!", message: "You will receive an email shortly.")
                    }
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(submitAction)
        self.present(alertController, animated: true, completion: nil)
        alertController.view.tintColor = Constants.data.lightBlue
    }

}
