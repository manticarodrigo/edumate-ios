//
//  ContactsViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 3/6/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import QuartzCore

class ContactsTableViewController: UITableViewController, UITextFieldDelegate, SearchTextFieldDelegate {
    
    @IBOutlet weak var searchTextField: SearchTextField!
    
    var chats: [Chat]?
    var users: [User?]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Layout subviews
        self.view.layoutIfNeeded()
        // Setup navBar
        self.stylizeNavBar()
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
        // Remove empty cells
        self.tableView.tableFooterView = UIView()
        // Setup pull to refresh chats
        self.refreshControl?.tintColor = UIColor.darkGray
        self.refreshControl?.addTarget(self, action: #selector(observeChats), for: UIControlEvents.valueChanged)
        // Add gesture to hide keyboard
        self.hideKeyboardWhenTappedAround()
        // Observe chats
        self.refreshControl!.beginRefreshing()
        self.observeChats(self.refreshControl!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = self.dataForPopoverInTextField(self.searchTextField)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // self.stopObservingChats()
        self.dismissKeyboard()
    }
    
    // MARK: - UITextField Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - SearchTextField Methods
    
    func dataForPopoverInTextField(_ textfield: SearchTextField) -> [NSDictionary] {
        if let users = Constants.data.userData {
            return users
        } else {
            return []
        }
    }
    
    func textFieldShouldSelect(_ textField: SearchTextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: SearchTextField, withSelection data: NSDictionary) {
        let user = data["User"] as! User
        self.performSegue(withIdentifier: "profile", sender: user)
        textField.text = nil
    }
    
    // MARK: - Chat Data Methods
    
    func observeChats(_ refreshControl: UIRefreshControl) {
        if let currentUser = UserController.shared.currentUser {
            ChatController.observeChatsForUser(currentUser) { (chats, users) in
                self.chats = []
                self.users = []
                var unreadCount = 0
                if let chats = chats, let users = users {
                    self.chats = chats
                    self.users = users
                    var chatCount = 0
                    for chat in chats {
                        if let typingDict = chat.typing {
                            self.typingAt(typing: typingDict, index: chatCount)
                        }
                        if let count = chat.unread?[currentUser.identifier!] as? Int {
                            unreadCount += count
                        }
                        chatCount += 1
                    }
                } else {
                    self.chats = nil
                    self.users = nil
                }
                self.tableView.reloadData()
                if self.refreshControl!.isRefreshing {
                    self.refreshControl!.endRefreshing()
                }
                if let contactsTab = self.tabBarController?.tabBar.items?[1] {
                    if unreadCount > 0 {
                        contactsTab.badgeValue = "\(unreadCount)"
                    } else {
                        contactsTab.badgeValue = nil
                    }
                }
            }
        }
    }
    
    func stopObservingChats() {
        if let chats = self.chats {
            ChatController.stopObservingChats(chats)
        }
    }
    
    func typingAt(typing: NSDictionary, index: Int) {
        let notCurrent = typing.filter({($0.0 as! String) != UserController.shared.currentUser!.identifier!})
        if notCurrent.count > 0 {
            if let user = self.users?[index], var chat = self.chats?[index] {
                chat.lastMessage = "\(user.firstName()) is typing..."
                self.chats![index] = chat
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.chats != nil {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = .singleLine
            return 1
        } else {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
            noDataLabel.text = "NO CONVERSATIONS YET."
            noDataLabel.textColor = UIColor.lightGray
            noDataLabel.textAlignment = .center
            self.tableView.backgroundView = noDataLabel
            self.tableView.separatorStyle = .none
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = Int()
        if let chats = self.chats {
            count = chats.count
        }
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactTableViewCell
        
        if let user = self.users?[indexPath.row] {
            cell.imgView!.loadImageWithIdentifier(user.identifier!)
            cell.nameLabel!.text = user.name
        } else {
            cell.imgView!.image = UIImage(named: "user-placeholder.png")
            cell.nameLabel!.text = "Unknown User"
        }
        
        if let chat = chats?[indexPath.row] {
            cell.messageLabel!.text = chat.lastMessage
            let date = Date(timeIntervalSince1970: TimeInterval(chat.timestamp))
            let string = self.stringForDate(date: date)
            cell.timeLabel.text = string
            if let currentUser = UserController.shared.currentUser, let unreadCount = chat.unread?[currentUser.identifier!] as? Int, unreadCount > 0 {
                cell.countLabel.text = "\(unreadCount)"
                cell.countLabel.isHidden = false
            } else {
                cell.countLabel.isHidden = true
            }
        } else {
            cell.messageLabel!.text = "Error loading last message."
            cell.timeLabel.text = ""
            cell.countLabel.isHidden = true
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let chat = self.chats![indexPath.row]
        
        var actions = [UITableViewRowAction]()
        
        let report = UITableViewRowAction(style: .normal, title: "REPORT") { action, index in
            let alertController = UIAlertController(title: "Report User", message: "Please send us a message describing their behavior.", preferredStyle: .alert)
            alertController.addTextField { (messageField) in
                messageField.placeholder = "Enter message"
            }
            let messageField = alertController.textFields![0]
            let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel, handler: nil)
            let submitAction = UIAlertAction(title: "SUBMIT", style: .default) { (_) -> Void in
                if messageField.text != nil {
                    ChatController.userForChat(chat, completion: { (user) in
                        if let user = user {
                            let report = ["sender": UserController.shared.currentUser.identifier!, "suspect": user, "message": messageField.text!] as [String : Any]
                            FirebaseController.base.child("reports").childByAutoId().setValue(report)
                        } else {
                            self.displayAlert("Oops!", message: "An error occurred. Please try again.")
                        }
                    })
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(submitAction)
            self.present(alertController, animated: true, completion: nil)
            alertController.view.tintColor = Constants.data.lightBlue
        }
        report.backgroundColor = UIColor.lightGray
        actions.append(report)
        
        let archive = UITableViewRowAction(style: .normal, title: "ARCHIVE") { action, index in
            ChatController.removeUserFromChat(UserController.shared.currentUser, chat: chat, completion: { (success) in
                if success {
                    self.displayAlert("Success!", message: "You left the conversation.")
                    self.observeChats(self.refreshControl!)
                } else {
                    self.displayAlert("Oops!", message: "There was a problem deleting the chat. Please try again.")
                }
            })
        }
        archive.backgroundColor = Constants.data.fadedRed
        actions.append(archive)
        
        return actions
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.chats != nil {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Allow swipe to display the actions
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let user = self.users?[indexPath.row] {
            self.chatWithUser(user: user)
        }
    }
    
    // MARK: - Navigation
    
    func chatWithUser(user: User) {
        ChatController.chatWithUser(user) { (chat) in
            if let chat = chat {
                let chatDict = ["Chat": chat, "User": user] as [String : Any]
                self.performSegue(withIdentifier: "chat", sender: chatDict)
            } else {
                self.displayAlert("Oops!", message: "An error occurred. Please try again.")
            }
        }
    }
    
    @IBAction func composeButtonPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "users", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "profile" {
            if let user = sender as? User {
                let nav = segue.destination as! UINavigationController
                let profileVc = nav.topViewController as! ProfileViewController
                profileVc.user = user
            }
        }
        if segue.identifier == "users" {
            let searchVC = segue.destination as! SearchTableViewController
            searchVC.delegate = self
            searchVC.searchType = 0
        }
        if segue.identifier == "chat" {
            if let chatDict = sender as? [String : Any] {
                let chatVc = segue.destination as! ChatViewController
                chatVc.chat = chatDict["Chat"] as! Chat?
                chatVc.user = chatDict["User"] as! User?
            }
        }
    }
    
}

extension ContactsTableViewController : SearchDelegate {
    
    func resultSelected(_ result: Any) {
        let user = result as! User
        print("selected: \(user.name)")
        self.chatWithUser(user: user)
    }
    
    func stringForDate(date: Date) -> String {
        let today = Date()
        let yesterday = NSCalendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = NSCalendar.current.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = NSCalendar.current.date(byAdding: .day, value: -3, to: today)!
        let fourDaysAgo = NSCalendar.current.date(byAdding: .day, value: -4, to: today)!
        let fiveDaysAgo = NSCalendar.current.date(byAdding: .day, value: -5, to: today)!
        if date.monthDayYear() == today.monthDayYear() {
            return date.timeString()
        } else if date.monthDayYear() == yesterday.monthDayYear() {
            return "Yesterday \(date.timeString())"
        } else if date.monthDayYear() == twoDaysAgo.monthDayYear() {
            return "\(twoDaysAgo.dayOfWeek()) \(twoDaysAgo.timeString())"
        } else if date.monthDayYear() == threeDaysAgo.monthDayYear() {
            return "\(threeDaysAgo.dayOfWeek()) \(threeDaysAgo.timeString())"
        } else if date.monthDayYear() == fourDaysAgo.monthDayYear() {
            return "\(fourDaysAgo.dayOfWeek()) \(fourDaysAgo.timeString())"
        } else if date.monthDayYear() == fiveDaysAgo.monthDayYear() {
            return "\(fiveDaysAgo.dayOfWeek()) \(fiveDaysAgo.timeString())"
        } else {
            return date.shortMonthDayYearHour()
        }
    }
    
}
