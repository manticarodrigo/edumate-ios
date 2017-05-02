//
//  SubjectTableViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 11/8/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class SubjectsTableViewController: UITableViewController {
    
    var subjects = [Int: Bool]()
    var tutors = [Int]()
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup NavBar
        // self.stylizeNavBar()
        // Remove tableview empty cells
        self.tableView.tableFooterView = UIView()
        // Setup subject array
        if let user = self.user {
            self.checkIfUserTutors(user: user)
        }
    }
    
    func checkIfUserTutors(user: User) {
        var subjectCount = 0
        for subject in Constants.data.subjects {
            let key = subject.key
            UserController.userTutors(user, subject: key, completion: { (tutors) in
                if tutors {
                    self.subjects.updateValue(true, forKey: key)
                    self.tutors.append(key)
                } else {
                    self.subjects.updateValue(false, forKey: key)
                }
                subjectCount += 1
                if subjectCount == Constants.data.subjects.count {
                    self.tableView.reloadData()
                }
            })
        }
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        var count = 0
        if let user = self.user {
            if user == UserController.shared.currentUser! {
                count = 1
            } else {
                if self.tutors.count > 0 {
                    count = 1
                } else {
                    let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
                    noDataLabel.text = "NO SUBJECTS FOUND."
                    noDataLabel.textColor = UIColor.lightGray
                    noDataLabel.textAlignment = .center
                    self.tableView.separatorStyle = .none
                    self.tableView.backgroundView = noDataLabel
                    count = 0
                }
            }
        }
        return count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        if let user = self.user {
            if user == UserController.shared.currentUser! {
                count = self.subjects.count
            } else {
                count = self.tutors.count
            }
        }
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "subjectCell", for: indexPath)
        
        if let user = self.user {
            if user == UserController.shared.currentUser! {
                cell.textLabel?.text = Constants.data.subjects[indexPath.row]
                if self.subjects[indexPath.row] == true {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else {
                cell.textLabel?.text = Constants.data.subjects[self.tutors[indexPath.row]]
                cell.accessoryType = .checkmark
            }
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let user = self.user {
            if user == UserController.shared.currentUser! {
                if self.subjects[indexPath.row] == true {
                    UserController.untutor(indexPath.row) { (success) in
                        self.displayAlert("Success!", message: "You no longer tutor \(Constants.data.subjects[indexPath.row]!).")
                        self.subjects[indexPath.row] = false
                        self.tableView.reloadData()
                    }
                } else {
                    UserController.tutor(indexPath.row) { (success) in
                        self.displayAlert("Success!", message: "You now tutor \(Constants.data.subjects[indexPath.row]!).")
                        self.subjects[indexPath.row] = true
                        self.tableView.reloadData()
                    }
                }
            }
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
