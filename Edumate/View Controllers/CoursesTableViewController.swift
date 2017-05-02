//
//  CoursesTableViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 11/10/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class CoursesTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, UITextFieldDelegate, SearchTextFieldDelegate {
    
    @IBOutlet weak var searchTextField: SearchTextField!
    
    var courses: [[Course]]?
    var terms: [String]?
    var joined: [[Bool]]?
    
    var storedOffsets = [Int: CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup navBar
        self.stylizeNavBar()
        self.navigationController?.navigationBar.addDropShadow()
        // Create variables for view size elements
        let screen = UIScreen.main.bounds
        let statusBarHeight = CGFloat(20)
        let navBarHeight = (self.navigationController?.navigationBar.frame.size.height)!
        let tabBarHeight = (self.tabBarController?.tabBar.frame.size.height)!
        let frame = CGRect(x: 0, y: 0, width: screen.width, height: screen.height - navBarHeight - tabBarHeight - statusBarHeight)
        // Setup search text field
        self.searchTextField.delegate = self
        self.searchTextField.searchDelegate = self
        self.searchTextField.popoverSize = CGRect(x: 0, y: navBarHeight, width: screen.width, height: frame.height)
        // Setup pull to refresh chats
        self.refreshControl?.tintColor = UIColor.white
        self.refreshControl?.addTarget(self, action: #selector(loadUserCourses), for: UIControlEvents.valueChanged)
        // Remove separators
        self.tableView.separatorStyle = .none
        // Remove empty cells
        self.tableView.tableFooterView = UIView()
        // Add gesture to dismiss keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadUserCourses()
        _ = self.dataForPopoverInTextField(self.searchTextField)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissKeyboard()
    }
    
    // MARK: - UITextField Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - SearchTextField Methods
    
    func dataForPopoverInTextField(_ textfield: SearchTextField) -> [NSDictionary] {
        if let courses = Constants.data.courseData {
            return courses
        } else {
            return []
        }
    }
    
    func textFieldShouldSelect(_ textField: SearchTextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: SearchTextField, withSelection data: NSDictionary) {
        let course = data["Course"] as! Course
        self.performSegue(withIdentifier: "course", sender: course)
        textField.text = nil
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let course = sender as? Course {
            let nav = segue.destination as! UINavigationController
            let courseTableVc = nav.topViewController as! CourseTableViewController
            courseTableVc.course = course
        } else if let indexPath = sender as? IndexPath {
            if let course = self.courses?[indexPath.section][indexPath.row] {
                if segue.identifier == "course" {
                    let nav = segue.destination as! UINavigationController
                    let courseVc = nav.topViewController as! CourseTableViewController
                    courseVc.course = course
                }
                if segue.identifier == "chat" {
                    let chat = Chat(lastMessage: "", timestamp: 0, typing: nil, unread: [:], identifier: course.identifier!)
                    let chatVc = segue.destination as! ChatViewController
                    chatVc.chat = chat
                    chatVc.course = course
                }
            }
        }
    }
    
    // MARK: - Course Data Methods
    
    func loadUserCourses() {
        self.courses = nil
        self.terms = nil
        if let currentUser = UserController.shared.currentUser {
            CourseController.coursesForUser(currentUser) { (userCourses) in
                var courses = [[Course]]()
                var terms = [String]()
                if let userCourses = userCourses {
                    for course in userCourses {
                        if terms.contains(course.term.uppercased()) == false {
                            terms.append(course.term.uppercased())
                        }
                    }
                    for term in terms {
                        let index = terms.index(of: term)
                        let coursesInTerm = userCourses.filter({$0.term.uppercased() == term})
                        courses.insert(coursesInTerm, at: index!)
                    }
                }
                CourseController.fetchNewestCourses { (newCourses) in
                    if let newCourses = newCourses {
                        let term = "NEWEST"
                        terms.insert(term, at: 0)
                        courses.insert(newCourses, at: 0)
                    }
                    self.checkIfJoinedCourses(courses: courses, in: terms)
                }
            }
        } else {
            self.tabBarController?.performSegue(withIdentifier: "login", sender:nil)
        }
    }
    
    func checkIfJoinedCourses(courses: [[Course]], in terms: [String]) {
        var joinedArray = [[Bool]]()
        for termCount in 0...terms.count-1 {
            var joinedInTerm = [Bool]()
            var coursesInTermCount = 0
            for course in courses[termCount] {
                if let currentUser = UserController.shared.currentUser {
                    CourseController.userJoined(currentUser, course: course, completion: { (joined) in
                        if joined {
                            joinedInTerm.append(true)
                        } else {
                            joinedInTerm.append(false)
                        }
                        coursesInTermCount += 1
                        if coursesInTermCount == courses[termCount].count {
                            joinedArray.insert(joinedInTerm, at: termCount)
                            if termCount == terms.count-1 {
                                self.courses = courses
                                self.terms = terms
                                self.joined = joinedArray
                                self.tableView.reloadData()
                                self.refreshControl?.endRefreshing()
                            }
                        }
                    })
                }
            }
        }
    }
    
    // MARK: - Action Sheet Methods
    
    func showCourse(for cell: UICollectionViewCell, at indexPath: IndexPath) {
        self.performSegue(withIdentifier: "course", sender: indexPath)
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let courses = self.courses {
            self.tableView!.backgroundView = nil
            return courses.count
        } else {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView!.bounds.size.width, height: self.tableView!.bounds.size.height))
            noDataLabel.text = "NO COURSES FOUND."
            noDataLabel.textColor = UIColor.white
            noDataLabel.textAlignment = .center
            self.tableView!.backgroundView = noDataLabel
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.textLabel?.textAlignment = .center
        headerView.textLabel?.textColor = UIColor.white
        headerView.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightSemibold)
        headerView.backgroundView?.backgroundColor = Constants.data.lightBlue
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let terms = self.terms {
            return terms[section]
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let tableViewCell = cell as? CourseTableViewCell else { return }
        
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.section)
        tableViewCell.collectionViewOffset = storedOffsets[indexPath.section] ?? 0
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let tableViewCell = cell as? CourseTableViewCell else { return }
        
        storedOffsets[indexPath.section] = tableViewCell.collectionViewOffset
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }

}

extension CoursesTableViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - Collection View Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let courses = self.courses {
            return courses[collectionView.tag].count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! CourseCollectionViewCell
        if let courses = self.courses, courses.count > 0 {
            let course = courses[collectionView.tag][indexPath.row]
            cell.subjectLabel.text = Constants.data.subjects[course.subject]
            self.setupDynamicLabel(label: cell.subjectLabel)
            cell.nameLabel.text = course.name
            if let joined = self.joined?[collectionView.tag][indexPath.row] {
                if joined {
                    cell.dotView.backgroundColor = Constants.data.lightGreen
                } else {
                    cell.dotView.backgroundColor = Constants.data.fadedRed
                }
            } else {
                cell.dotView.backgroundColor = Constants.data.fadedRed
            }
        }
        return cell
    }
    
    // MARK: - Collection View Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CourseCollectionViewCell {
            let index = IndexPath(row: indexPath.row, section: collectionView.tag)
            self.showCourse(for: cell, at: index)
            cell.cardView.backgroundColor = UIColor.white.darker()
            UIView.animate(withDuration: 0.3, animations: {() -> Void in
                cell.cardView.backgroundColor = UIColor.white
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CourseCollectionViewCell {
            cell.cardView.backgroundColor = UIColor.white.darker()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CourseCollectionViewCell {
            cell.cardView.backgroundColor = UIColor.white
        }
    }
    
}

extension CoursesTableViewController {
    
    func setupDynamicLabel(label: UILabel) {
        label.lineBreakMode = .byWordWrapping
        let stringArray = label.text?.components(separatedBy: " ")
        var attributedString = NSMutableAttributedString()
        for string in stringArray! {
            var text = string
            if text != stringArray!.last && stringArray!.count > 1 {
                text.append("\n")
            }
            attributedString += (NSMutableAttributedString(string : text, font: label.font, maxWidth: 80)!)
        }
        label.attributedText = attributedString
    }
    
}
