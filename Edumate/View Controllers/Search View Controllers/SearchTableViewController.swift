//
//  SearchTableViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/20/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

protocol SearchDelegate {
    func resultSelected(_ result: Any) -> Void
}

class SearchTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    var delegate: SearchDelegate!
    var searchType: Int?
    
    enum ViewMode: Int {
        case user = 0
        case all = 1
        func users(_ completion: @escaping (_ users:[User]?) -> Void) {
            switch self {
            case .user:
                UserController.followedBy(UserController.shared.currentUser) { (followers) -> Void in
                    if let followers = followers {
                        completion(followers)
                    } else {
                        completion(nil)
                    }
                }
            case .all:
                UserController.observeAllUsers() { (users) -> Void in
                    if let users = users {
                        completion(users)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
        func courses(_ completion: @escaping (_ courses:[Course]?) -> Void) {
            switch self {
            case .user:
                CourseController.coursesForUser(UserController.shared.currentUser, completion: { (courses) in
                    if let courses = courses {
                        completion(courses)
                    } else {
                        completion(nil)
                    }
                })
            case .all:
                CourseController.observeAllCourses() { (courses) in
                    if let courses = courses {
                        completion(courses)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Properties
    
    @IBOutlet weak var segmentedControl: StyledSegmentedControl!
    var dataSource: [Any]?
    var mode: ViewMode {
        get {
            return ViewMode(rawValue: segmentedControl.selectedIndex)!
        }
    }
    
    var searchController: UISearchController!
    
    
    // MARK: - View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup navBar
        self.stylizeNavBar()
        // Setup segmented control
        self.segmentedControl.addTarget(self, action: #selector(self.segmentedValueChanged), for: .valueChanged)
        // Setup pull to refresh chats
        self.refreshControl?.tintColor = UIColor.darkGray
        self.refreshControl?.addTarget(self, action: #selector(self.updateViewBasedOnMode), for: UIControlEvents.valueChanged)
        // Setup search controller
        self.setUpSearchController()
        // Remove empty cells
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Load users or courses
        self.updateViewBasedOnMode()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setUpSearchBar()
    }
    
    func updateViewBasedOnMode() {
        if self.searchType == 0 {
            self.segmentedControl.items[0] = "FOLLOWING"
            mode.users() { (users) -> Void in
                if let users = users {
                    self.dataSource = users as [User]?
                    self.reloadTableView()
                } else {
                    self.dataSource = nil
                    self.reloadTableView()
                }
                
            }
        } else if self.searchType == 1 {
            self.segmentedControl.items[0] = "JOINED"
            mode.courses() { (courses) -> Void in
                if let courses = courses {
                    self.dataSource = courses as [Course]?
                    self.reloadTableView()
                } else {
                    self.dataSource = nil
                    self.reloadTableView()
                }
            }
        }
    }
    
    func reloadTableView() {
        self.tableView.reloadData()
        if (self.refreshControl?.isRefreshing)! {
            self.refreshControl?.endRefreshing()
        }
    }
    
    func segmentedValueChanged() {
        self.updateViewBasedOnMode()
    }
    
    // MARK: - Search Controller Delegate
    
    func setUpSearchController() {
        let resultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchResultsTableViewController")
        self.searchController = UISearchController(searchResultsController: resultsController)
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.searchBarStyle = .minimal
        self.searchController.searchBar.tintColor = UIColor.white
        self.searchController.searchBar.backgroundColor = Constants.data.lightBlue
        self.searchController.searchBar.addDropShadow()
        self.searchController.searchBar.placeholder = "Search"
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.becomeFirstResponder()
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.definesPresentationContext = true
        self.tableView.tableHeaderView = self.searchController.searchBar
    }
    
    func setUpSearchBar() {
        let searchBar = self.searchController.searchBar
        if let cancelButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            let font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightBold)
            let attributedTitle = NSAttributedString(string: "CANCEL", attributes: [NSFontAttributeName : font])
            cancelButton.setAttributedTitle(attributedTitle, for: .normal)
        }
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = UIColor.white
            textField.clearButtonMode = .never
            if textField.responds(to: #selector(getter: UITextField.attributedPlaceholder)) {
                let color = Constants.data.lightBlue
                let attributeDict = [NSForegroundColorAttributeName: color]
                textField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: attributeDict)
            }
            if let searchIconView = textField.leftView as? UIImageView {
                searchIconView.image = searchIconView.image?.withRenderingMode(.alwaysTemplate)
                searchIconView.tintColor = Constants.data.lightBlue
                
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let users = self.dataSource as? [User] {
            let searchTerm = searchController.searchBar.text!.lowercased()
            let resultsViewController = searchController.searchResultsController as! SearchResultsTableViewController
            resultsViewController.resultsDataSource = users.filter({$0.name.lowercased().contains(searchTerm)})
            resultsViewController.tableView.reloadData()
        }
        if let courses = self.dataSource as? [Course] {
            let searchTerm = searchController.searchBar.text!.lowercased()
            let resultsViewController = searchController.searchResultsController as! SearchResultsTableViewController
            resultsViewController.resultsDataSource = courses.filter({$0.name.lowercased().contains(searchTerm)})
            resultsViewController.tableView.reloadData()
        }
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.dataSource != nil {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = .singleLine
            return 1
        } else {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
            noDataLabel.textColor = UIColor.gray
            noDataLabel.textAlignment = .center
            self.tableView.separatorStyle = .none
            self.tableView.backgroundView = noDataLabel
            if self.searchType == 0 {
                noDataLabel.text = "NO PEOPLE FOLLOWED YET."
            } else {
                noDataLabel.text = "NO COURSES JOINED YET."
            }
            return 0
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30))
        headerView.backgroundColor = Constants.data.lightBlue
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let users = self.dataSource as? [User] {
            return users.count
        } else if let courses = self.dataSource as? [Course] {
            return courses.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
        if let users = self.dataSource as? [User] {
            let user = users[indexPath.row]
            cell.textLabel?.text = user.name
            cell.detailTextLabel?.text = user.university
        }
        if let courses = self.dataSource as? [Course] {
            let course = courses[indexPath.row]
            cell.textLabel?.text = course.name
            cell.detailTextLabel?.text = course.university
        }
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _ = self.navigationController?.popViewController(animated: false)
        let cell = tableView.cellForRow(at: indexPath)
        if let users = self.dataSource as? [User] {
            if let indexPath = tableView.indexPath(for: cell!) {
                let user = users[indexPath.row]
                delegate.resultSelected(user)
            } else if let indexPath = (searchController.searchResultsController as? SearchResultsTableViewController)?.tableView.indexPath(for: cell!) {
                if let user = (searchController.searchResultsController as! SearchResultsTableViewController).resultsDataSource?[indexPath.row] {
                    delegate.resultSelected((user as! User))
                }
            }
        } else if let courses = self.dataSource as? [Course] {
            if let indexPath = tableView.indexPath(for: cell!) {
                let course = courses[indexPath.row]
                delegate.resultSelected(course)
            } else if let indexPath = (searchController.searchResultsController as? SearchResultsTableViewController)?.tableView.indexPath(for: cell!) {
                if let course = (searchController.searchResultsController as! SearchResultsTableViewController).resultsDataSource?[indexPath.row] {
                    delegate.resultSelected((course as! Course))
                }
            }
        }
    }

}
