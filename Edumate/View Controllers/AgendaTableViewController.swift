//
//  AgendaTableViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/31/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class AgendaTableViewController: UITableViewController {
    
    enum ViewMode: Int {
        case upcoming = 0
        case all = 1
        func assignments(_ completion: @escaping (_ assignments:[[Assignment]]?) -> Void) {
            switch self {
            case .upcoming:
                AssignmentController.assignmentsForUser(UserController.shared.currentUser, completion: { (userAssignments) in
                    let upcomingDates = AgendaTableViewController().fetchUpcomingDates()
                    var assignments = [[Assignment]]()
                    for date in upcomingDates {
                        let assignmentsForDate = userAssignments?.filter({Date(timeIntervalSince1970: TimeInterval($0.dueDate)).monthDayYear() == date.monthDayYear()})
                        assignments.append(assignmentsForDate ?? [])
                    }
                    completion(assignments)
                })
            case .all:
                AssignmentController.assignmentsForUser(UserController.shared.currentUser, completion: { (userAssignments) in
                    if let userAssignments = userAssignments {
                        var assignments = [[Assignment]]()
                        var dates = [String]()
                        for assignment in userAssignments {
                            let dueDate = Date(timeIntervalSince1970: TimeInterval(assignment.dueDate)).monthDayYear()
                            if dates.contains(dueDate) == false {
                                dates.append(dueDate)
                            }
                        }
                        for date in dates {
                            let assignmentsForDate = userAssignments.filter({Date(timeIntervalSince1970: TimeInterval($0.dueDate)).monthDayYear() == date})
                            let index = dates.index(of: date)
                            assignments.insert(assignmentsForDate, at: index!)
                        }
                        completion(assignments)
                    } else {
                        completion(nil)
                    }
                })
            }
        }
    }
    
    // MARK: - Properties
    
    @IBOutlet weak var segmentedControl: StyledSegmentedControl!
    var assignmentsDataSource: [[Assignment]]?
    var mode: ViewMode {
        get {
            return ViewMode(rawValue: segmentedControl.selectedIndex)!
        }
    }
    
    // MARK: - View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup navBar
        self.stylizeNavBar()
        self.navigationController?.navigationBar.addDropShadow()
        // Register section header view nib
        let nib = UINib(nibName: "AgendaSectionHeader", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: "AgendaSectionHeader")
        // Setup segmented control
        self.segmentedControl.addTarget(self, action: #selector(self.segmentedValueChanged), for: .valueChanged)
        // Setup pull to refresh chats
        self.refreshControl?.tintColor = UIColor.white
        self.refreshControl?.addTarget(self, action: #selector(self.updateViewBasedOnMode), for: UIControlEvents.valueChanged)
        // Remove tableview empty cells
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Remove tableview separators
        self.tableView.separatorStyle = .none
        self.tableView.separatorInset = .zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Setup view based on mode
        self.updateViewBasedOnMode()
    }
    
    func updateViewBasedOnMode() {
        mode.assignments() { (assignments) -> Void in
            if let assignments = assignments {
                self.assignmentsDataSource = assignments
            } else {
                self.assignmentsDataSource = nil
            }
            self.tableView.reloadData()
            if self.refreshControl!.isRefreshing {
                self.refreshControl!.endRefreshing()
            }
        }
    }
    
    func segmentedValueChanged() {
        self.updateViewBasedOnMode()
    }
    
    // MARK: - Date Methods
    
    func fetchUpcomingDates() -> [Date] {
        let day:TimeInterval = 24*60*60 // One day
        let currentDate = Date() // Now
        let endDate = currentDate.addingTimeInterval(24*60*60*15) // 15 Days later
        var nextDate = Date()
        var upcomingDates = [Date]()
        while nextDate.compare(endDate) == ComparisonResult.orderedAscending {
            upcomingDates.append(nextDate)
            nextDate = nextDate.addingTimeInterval(day)
        }
        return upcomingDates
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let assignments = self.assignmentsDataSource {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = .singleLine
            return assignments.count
        } else {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
            noDataLabel.text = "NO ASSIGNMENTS FOUND."
            noDataLabel.textColor = UIColor.white
            noDataLabel.textAlignment = .center
            self.tableView.separatorStyle = .none
            self.tableView.backgroundView = noDataLabel
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "AgendaSectionHeader") as! AgendaSectionHeader
        if let assignments = self.assignmentsDataSource?[section] {
            var date = Date()
            if segmentedControl.selectedIndex == 0 {
                date = self.fetchUpcomingDates()[section]
            } else if assignments.count > 0 {
                date = Date(timeIntervalSince1970: TimeInterval(assignments[0].dueDate))
            }
            let dateFormatter = DateFormatter()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year, .weekday], from: date)
            let month = calendar.shortMonthSymbols[components.month! - 1]
            let day = components.day!
            let weekDay = dateFormatter.shortWeekdaySymbols[components.weekday! - 1]
            header.dayLabel.text = weekDay.uppercased()
            header.dateLabel.text = "\(month) \(day)"
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 1
        if let assignments = self.assignmentsDataSource {
            if assignments[section].count > 0 {
                count = assignments[section].count
            }
        }
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "agendaCell", for: indexPath) as! AgendaTableViewCell
        if let assignments = self.assignmentsDataSource {
            if assignments[indexPath.section].count > 0 {
                let assignment = assignments[indexPath.section][indexPath.row]
                cell.assignmentLabel?.text = assignment.name
                let dueDate:Date = Date(timeIntervalSince1970: TimeInterval(assignment.dueDate))
                cell.timeLabel.text? = dueDate.timeString()
                if let description = assignment.description {
                    cell.descriptionLabel.text = description
                } else {
                    cell.descriptionLabel.text = "No description."
                }
                AssignmentController.courseForAssignment(assignment, completion: { (course) in
                    if let course = course {
                        cell.courseLabel?.text = Constants.data.subjects[course.subject]
                    } else {
                        cell.courseLabel?.text = nil
                    }
                })
            } else {
                cell.assignmentLabel?.text = "All set!"
                cell.descriptionLabel?.text = "Tap to add new."
                cell.timeLabel.text = ""
                cell.courseLabel?.text = ""
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height : CGFloat = 60
        if let assignments = self.assignmentsDataSource, assignments[indexPath.section].count > 0 {
            let assignment = assignments[indexPath.section][indexPath.row]
            let estimatedSize = CGSize(width: tableView.frame.size.width - 106, height: 1000)
            let font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
            if let description = assignment.description {
                let estimatedFrame = description.estimateFrame(for: estimatedSize, with: font)
                height = estimatedFrame.size.height + 55
            }
        }
        return height
    }
    
    // MARK: Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? AgendaTableViewCell {
            UIView.animate(withDuration: 0.3, animations: {() -> Void in
                cell.bubbleView.backgroundColor = UIColor.white
            })
            self.performSegue(withIdentifier: "assignment", sender: indexPath)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? AgendaTableViewCell {
            cell.bubbleView.backgroundColor = UIColor.white.darker()
        }
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? AgendaTableViewCell {
            cell.bubbleView.backgroundColor = UIColor.white
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "assignment" {
            if let indexPath = sender as? IndexPath {
                if let assignments = self.assignmentsDataSource {
                    if assignments[indexPath.section].count > 0 {
                        let assignment = assignments[indexPath.section][indexPath.row]
                        let nav = segue.destination as! UINavigationController
                        let assignmentVc = nav.topViewController as! AssignmentTableViewController
                        assignmentVc.assignment = assignment
                    } else {
                        let date = self.fetchUpcomingDates()[indexPath.section]
                        let nav = segue.destination as! UINavigationController
                        let assignmentVc = nav.topViewController as! AssignmentTableViewController
                        assignmentVc.dueDate = date
                    }
                }
            }
        }
    }
    
}
