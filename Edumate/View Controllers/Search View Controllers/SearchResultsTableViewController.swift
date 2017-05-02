//
//  SearchResultsTableViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/20/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class SearchResultsTableViewController: UITableViewController {

    var resultsDataSource: [Any]?
    
    // MARK: - View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Remove empty cells
        self.tableView.tableFooterView = UIView()
    }
    
    // MARK: - Table View Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let results = self.resultsDataSource {
            return results.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath)
        if let users = self.resultsDataSource as? [User] {
            let user = users[indexPath.row]
            cell.textLabel?.text = user.name
            cell.detailTextLabel?.text = user.university
        }
        if let courses = self.resultsDataSource as? [Course] {
            let course = courses[indexPath.row]
            cell.textLabel?.text = course.name
            cell.detailTextLabel?.text = course.university
        }
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let searchVC = self.presentingViewController as! SearchTableViewController
        _ = searchVC.navigationController?.popViewController(animated: true)
        if let users = self.resultsDataSource as? [User] {
            let user = users[indexPath.row]
            searchVC.delegate.resultSelected(user)
        }
        if let courses = self.resultsDataSource as? [Course] {
            let course = courses[indexPath.row]
            searchVC.delegate.resultSelected(course)
        }
    }

}
