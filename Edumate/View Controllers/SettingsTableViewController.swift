//
//  SettingsTableViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 6/27/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class SettingsTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "SETTINGS"
    }
    
    // MARK: - Miscellaneous Methods
    
    func rateApp() {
        let alert = UIAlertController(title: "Rate Us", message: "Thank you for using Edumate. Please take a minute to rate us on the app store!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) in
            let appID = "1126689723"
            let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)")!
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        alert.view.tintColor = Constants.data.lightBlue
    }
    
    func shareLink(sender: UITableViewCell) {
        let textToShare = "Connect with your classmates and instructors on Edumate!  Check it out on the app store!"
        let appID = "1126689723"
        if let appURL = NSURL(string: "https://itunes.apple.com/us/app/myapp/id\(appID)?ls=1&mt=8") {
            let objectsToShare = [textToShare, appURL] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = sender
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Account Details Methods
    
    func updateEmail() {
        // Prompt the user to re-provide their sign-in credentials
        let alertController = UIAlertController(title: "Update Email", message: "Please provide a new email address, and your current password.", preferredStyle: .alert)
        
        alertController.addTextField { (emailField) -> Void in
            emailField.placeholder = "New email"
            emailField.isSecureTextEntry = true
            emailField.keyboardType = .emailAddress
        }
        
        alertController.addTextField { (passwordField) -> Void in
            passwordField.placeholder = "Current password"
            passwordField.isSecureTextEntry = true
        }
        
        let newEmailField = alertController.textFields![0]
        let currentPasswordField = alertController.textFields![1]
        
        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel, handler: nil)
        
        let authenticateAction = UIAlertAction(title: "UPDATE", style: .default) { (_) -> Void in
            if newEmailField.text != nil && currentPasswordField.text != nil  {
                UserController.authenticateUserWithEmail(FirebaseController.auth!.currentUser!.email!, password: currentPasswordField.text!, completion: { (message, user) in
                    if let message = message {
                        self.displayAlert("Authentication Failed", message: message)
                    } else {
                        FirebaseController.auth!.currentUser!.updateEmail(newEmailField.text!) { error in
                            if error != nil {
                                self.displayAlert("Update Failed", message: "Could not update email, please try again.")
                            } else {
                                self.displayAlert("Update Successful", message: "Your email was successfully updated.")
                            }
                        }
                    }
                })
                
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(authenticateAction)
        
        self.present(alertController, animated: true, completion: nil)
        alertController.view.tintColor = Constants.data.lightBlue
    }
    
    func updatePassword() {
        // Prompt the user to re-provide their sign-in credentials
        let alertController = UIAlertController(title: "Update Password", message: "Please provide your current password, and a new one.", preferredStyle: .alert)
        
        alertController.addTextField { (currentPasswordField) -> Void in
            currentPasswordField.placeholder = "Current password"
            currentPasswordField.isSecureTextEntry = true
        }
        
        alertController.addTextField { (newPasswordField) -> Void in
            newPasswordField.placeholder = "New password"
            newPasswordField.isSecureTextEntry = true
        }
        
        let oldField = alertController.textFields![0]
        let newField = alertController.textFields![1]
        
        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel) { (_) in
        }
        
        let authenticateAction = UIAlertAction(title: "UPDATE", style: .default) { (_) -> Void in
            if oldField.text != nil && newField.text != nil  {
                UserController.authenticateUserWithEmail((FirebaseController.auth?.currentUser?.email)!, password: oldField.text!, completion: { (message, user) in
                    if let message = message {
                        self.displayAlert("Authentication Error", message: message)
                    } else {
                        FirebaseController.auth?.currentUser!.updatePassword(newField.text!) { error in
                            if error != nil {
                                self.displayAlert("Update Failed", message: "Could not update password, please try again.")
                            } else {
                                self.displayAlert("Update Successful", message: "Your password was successfully updated.")
                            }
                        }
                    }
                })
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(authenticateAction)
        
        self.present(alertController, animated: true, completion: nil)
        alertController.view.tintColor = Constants.data.lightBlue
    }
    
    func linkWithFacebook() {
        let fbLoginManager = FBSDKLoginManager()
        
        fbLoginManager.logIn(withReadPermissions: ["public_profile", "email", "user_friends"], from: self) { (result, error) -> Void in
            if error != nil {
                self.displayAlert("Facebook Authentication Failed.", message: "Please try again later.")
            } else if result?.isCancelled == true {
                self.displayAlert("Facebook Authentication Failed.", message: "You cancelled the authentication process.")
            } else {
                UserController.authenticateUserWithToken(FBSDKAccessToken.current().tokenString, completion: { (success, user) in
                    if success {
                        self.displayAlert("Facebook Authenticated.", message: "Your account has been linked with Facebook.")
                    } else {
                        self.displayAlert("Facebook Authentication Failed.", message: "Please try again later.")
                    }
                })
            }
        }
    }
    
    // MARK: - Account Management Methods
    
    func deleteAccount() {
        for profile in FirebaseController.auth!.currentUser!.providerData {
            let uid = profile.uid
            let name = profile.displayName
            if name != nil && uid.isEmpty != true {
                let fbLoginManager = FBSDKLoginManager()
                fbLoginManager.logIn(withReadPermissions: ["public_profile", "email", "user_friends"], from: self) { (result, error) -> Void in
                    if error != nil {
                        self.displayAlert("Facebook Authentication Failed.", message: "Please try again later.")
                    } else if result?.isCancelled == true {
                        self.displayAlert("Facebook Authentication Failed.", message: "You cancelled the authentication process.")
                    } else {
                        UserController.authenticateUserWithToken(FBSDKAccessToken.current().tokenString, completion: { (success, user) in
                            if success {
                                self.deleteDatabaseValues()
                                
                            } else {
                                self.displayAlert("Facebook Authentication Failed.", message: "Please try again later.")
                            }
                        })
                    }
                }
            } else {
                // Prompt the user to re-provide their sign-in credentials
                let alertController = UIAlertController(title: "Confirm Password", message: "Please enter your password before deleting your account.", preferredStyle: .alert)
                
                alertController.addTextField { (passwordField) -> Void in
                    passwordField.placeholder = "Password"
                    passwordField.isSecureTextEntry = true
                }
                
                let passwordField = alertController.textFields![0]
                
                let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel) { (_) in
                }
                
                let authenticateAction = UIAlertAction(title: "DELETE", style: .destructive) { (_) -> Void in
                    if passwordField.text != nil  {
                        // Reauthenticate user
                        UserController.authenticateUserWithEmail(FirebaseController.auth!.currentUser!.email!, password: passwordField.text!, completion: { (message, user) in
                            // User re-authenticated
                            self.deleteDatabaseValues()
                        })
                    }
                }
                
                alertController.addAction(cancelAction)
                alertController.addAction(authenticateAction)
                
                self.present(alertController, animated: true, completion: nil)
                alertController.view.tintColor = Constants.data.lightBlue
            }
        }
    }
    
    func deleteDatabaseValues() {
        // Delete user from database
        FirebaseController.auth?.currentUser!.delete { error in
            if error != nil {
                // An error happened.
                self.displayAlert("Delete Failed", message: "Could not delete user, please try again.")
            } else {
                // Account deleted.
                self.logOut()
            }
        }
    }
    
    func logOut() {
        ((self.tabBarController?.selectedViewController as! UINavigationController).viewControllers[0] as! ProfileViewController).user = nil
        UserController.logoutCurrentUser()
        self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers![2]
        _ = self.navigationController?.popToRootViewController(animated: false)
    }
    
    // MARK: - Table View Data Source
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.gray
        header.textLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightSemibold)
        header.textLabel?.frame = header.frame
        header.textLabel?.textAlignment = .left
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Miscellaneous section
        if indexPath.section == 0 {
            // Rate us
            if indexPath.row == 0 {
                self.rateApp()
            }
            // Become a tutor
            if indexPath.row == 1 {
                self.performSegue(withIdentifier: "subjects", sender: self)
            }
            // Share with friends
            if indexPath.row == 2 {
                if let cell = tableView.cellForRow(at: indexPath) {
                    self.shareLink(sender: cell)
                }
            }
        }
        // Account Details section
        if indexPath.section == 1 {
            // Update email
            if indexPath.row == 0 {
                self.updateEmail()
            }
            // Update password
            if indexPath.row == 1 {
                self.updatePassword()
            }
            // Link with Facebook
            if indexPath.row == 2 {
                for profile in (FirebaseController.auth?.currentUser?.providerData)! {
                    let uid = profile.uid
                    let name = profile.displayName
                    if name != nil && uid.isEmpty != true {
                        self.displayAlert("Oops!", message: "You have already linked your account with Facebook.")
                    } else {
                        self.linkWithFacebook()
                    }
                }
            }
        }
        // Account Management section
        if indexPath.section == 2 {
            // Delete account
            if indexPath.row == 0 {
                self.deleteAccount()
            }
            // Logout
            if indexPath.row == 1 {
                self.logOut()
            }
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "subjects" {
            if let currentUser = UserController.shared.currentUser {
                let nav = segue.destination as! UINavigationController
                let subjectsVc = nav.topViewController as! SubjectsTableViewController
                subjectsVc.user = currentUser
            }
        }
    }
    
}
