//
//  ChatViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 5/30/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    @IBOutlet weak var messageCollectionView: UICollectionView!
    @IBOutlet weak var messageInputView: UIView!
    var messageInputViewBottomAnchor: NSLayoutConstraint?
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    var refreshControl:UIRefreshControl!
    
    var user: User?
    var course: Course?
    
    var chat: Chat?
    var messages: [Message]?
    var users: [User?]?
    
    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup nav bar
        self.navigationItem.titleView = self.subtitleTitleView(subtitle: "Tap to view profile.")
        self.navigationController?.navigationBar.addDropShadow()
        // Setup message collection view
        self.messageCollectionView.delegate = self
        self.messageCollectionView.dataSource = self
        self.messageCollectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        self.messageCollectionView.alwaysBounceVertical = true
        self.messageCollectionView.register(MessageCollectionViewCell.self, forCellWithReuseIdentifier: "messageCell")
        // Setup message text field
        self.messageTextField.delegate = self
        // Setup message input view bottom anchor
        self.messageInputViewBottomAnchor = self.messageInputView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        self.messageInputViewBottomAnchor?.isActive = true
        // Setup send button
        self.sendButton.setTitleColor(UIColor.lightGray, for: .disabled)
        // Setup refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = UIColor.darkGray
        self.refreshControl.addTarget(self, action: #selector(self.refreshObservers), for: .valueChanged)
        self.messageCollectionView!.addSubview(self.refreshControl)
        // Observe keyboard
        self.setupKeyboardObservers()
        // Observe messages
        self.observeMessages()
        // Add gesture to hide keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Observe typing
        self.observeTyping()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissKeyboard()
        self.removeKeyboardObserver()
        self.stopObservingChat()
    }
    
    // MARK: - Keyboard Methods
    
    func removeKeyboardObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func handleKeyboardDidShow() {
        if let messages = self.messages {
            if messages.count > 0 {
                let indexPath = IndexPath(item: messages.count - 1, section: 0)
                self.messageCollectionView.scrollToItem(at: indexPath, at: .top, animated: true)
            }
        }
    }
    
    func handleKeyboardWillShow(_ notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        self.messageInputViewBottomAnchor?.constant = -keyboardFrame.height
        UIView.animate(withDuration: keyboardDuration, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func handleKeyboardWillHide(_ notification: Notification) {
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        self.messageInputViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration, animations: {
            self.view.layoutIfNeeded()
            self.updateTypingStatus(with: false)
        })
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "user" {
            if let user = sender as? User {
                let nav = segue.destination as! UINavigationController
                let profileVc = nav.topViewController as! ProfileViewController
                profileVc.user = user
            }
        }
        if segue.identifier == "course" {
            if let course = sender as? Course {
                let nav = segue.destination as! UINavigationController
                let courseVc = nav.topViewController as! CourseTableViewController
                courseVc.course = course
            }
        }
    }
    
    func showProfile() {
        if let user = self.user {
            self.performSegue(withIdentifier: "user", sender: user)
        }
        if let course = self.course {
            self.performSegue(withIdentifier: "course", sender: course)
        }
    }
    
    // MARK: - TextField Methods
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text: NSString = (textField.text ?? "") as NSString
        let resultString = text.replacingCharacters(in: range, with: string)
        if resultString.trimmingCharacters(in: .whitespaces).isEmpty {
            // String does not contain symbols
            self.updateTypingStatus(with: false)
            self.sendButton.isEnabled = false
        } else {
            // String contains non-whitespace characters
            self.updateTypingStatus(with: true)
            self.sendButton.isEnabled = true
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.sendButton.isEnabled {
            self.sendButtonPressed(self)
        } else {
            if textField.text!.trimmingCharacters(in: .whitespaces).isEmpty {
                self.updateTypingStatus(with: false)
                textField.text = nil
            }
            self.dismissKeyboard()
        }
        return true
    }
    
    func updateTypingStatus(with bool: Bool) {
        if let chat = self.chat {
            ChatController.userIsTypingInChat(bool, chat: chat)
        }
    }
    
    // MARK: - Message Data Methods
    
    fileprivate func observeMessages() {
        if let chat = self.chat {
            // Observe messages
            ChatController.observeMessagesIn(chat) { (messages) in
                self.resetUnreadCount()
                if let messages = messages {
                    let sortedMessages = self.sortMessages(messages: messages)
                    var users = [User?]()
                    var messageCount = 0
                    for message in sortedMessages {
                        UserController.userWithIdentifier(message.sender, completion: { (user) in
                            if let user = user {
                                users.append(user)
                            } else {
                                users.append(nil)
                            }
                            messageCount += 1
                            if messageCount == messages.count {
                                self.messages = sortedMessages
                                self.users = users
                                self.messageCollectionView.reloadData()
                                self.refreshControl.endRefreshing()
                                // Scroll to the last index
                                if let messages = self.messages {
                                    let indexPath = IndexPath(item: messages.count - 1, section: 0)
                                    self.messageCollectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                                }
                            }
                        })
                    }
                } else {
                    self.messages = nil
                    self.users = nil
                    self.messageCollectionView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    fileprivate func resetUnreadCount() {
        if let currentUser = UserController.shared.currentUser, var chat = self.chat {
            if let unreadCount = chat.unread?[currentUser.identifier!] as? Int, unreadCount > 0 {
                ChatController.userForChat(chat, completion: { (user) in
                    if let user = user {
                        if let otherUserCount = chat.unread?[user.identifier!] as? Int {
                            chat.unread = [user.identifier! : otherUserCount, currentUser.identifier! : 0]
                            chat.save()
                        } else {
                            chat.unread = [currentUser.identifier! : 0]
                            chat.save()
                        }
                        ChatController.chatWithIdentifier(chat.identifier!, completion: { (chat) in
                            if let chat = chat {
                                self.chat = chat
                            }
                        })
                    }
                })
            }
        }
    }
    
    fileprivate func observeTyping() {
        if let chat = self.chat {
            ChatController.observeTypingIn(chat, completion: { (users) in
                if let users = users {
                    var subtitleString = String()
                    if users.count > 1 {
                        for user in users {
                            if user == users.last {
                                subtitleString += "and \(user.firstName()) are typing..."
                            } else {
                                subtitleString += "\(user.firstName()), "
                            }
                        }
                    } else {
                        subtitleString = "\(users[0].firstName()) is typing..."
                    }
                    self.navigationItem.titleView = self.subtitleTitleView(subtitle: subtitleString)
                } else {
                    self.navigationItem.titleView = self.subtitleTitleView(subtitle: "Tap to view profile.")
                }
            })
        }
    }
    
    @objc fileprivate func refreshObservers() {
        self.stopObservingChat()
        self.observeMessages()
        self.observeTyping()
    }
    
    fileprivate func stopObservingChat() {
        if let chat = self.chat {
            ChatController.stopObservingChat(chat)
        }
    }
    
    fileprivate func sortMessages(messages: [Message]) -> [Message] {
        return messages.sorted(by: {TimeInterval($0.0.timestamp) < TimeInterval($0.1.timestamp)})
    }
    
    // MARK: - Message Submission Methods
    
    @IBAction func sendButtonPressed(_ sender: AnyObject) {
        self.sendButton.isEnabled = false
        if let text = self.messageTextField.text {
            if text.trimmingCharacters(in: .whitespaces).isEmpty == false {
                if let chat = self.chat {
                    if let user = self.user {
                        ChatController.sendMessageToUser(text, chat: chat, user: user, completion: { (message) in
                            if message == nil {
                                self.displayAlert("Oops!", message: "There was an error sending your message, please try again.")
                            }
                            self.finishSendingMessage()
                        })
                    } else if let course = self.course {
                        ChatController.sendMessageToCourse(text, chat: chat, course: course, completion: { (message) in
                            if message == nil {
                                self.displayAlert("Oops!", message: "There was an error sending your message, please try again.")
                            }
                            self.finishSendingMessage()
                        })
                    }
                }
            } else {
                self.finishSendingMessage()
            }
        }
    }
    
    func finishSendingMessage() {
        if let chat = self.chat {
            ChatController.chatWithIdentifier(chat.identifier!, completion: { (updatedChat) in
                if let updatedChat = updatedChat {
                    self.chat = updatedChat
                }
            })
        }
        self.messageTextField.text = nil
        self.updateTypingStatus(with: false)
        self.dismissKeyboard()
    }
    
    // MARK: - Collection View Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if self.messages != nil {
            self.messageCollectionView!.backgroundView = nil
            return 1
        } else {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.messageCollectionView!.bounds.size.width, height: self.messageCollectionView!.bounds.size.height))
            noDataLabel.text = "NO MESSAGES FOUND."
            noDataLabel.textColor = UIColor.lightGray
            noDataLabel.textAlignment = .center
            self.messageCollectionView!.backgroundView = noDataLabel
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let messages = self.messages {
            return messages.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "messageCell", for: indexPath) as! MessageCollectionViewCell
        
        if let message = self.messages?[indexPath.item] {
            cell.textView.text = message.text
            let estimatedSize = CGSize(width: 200, height: 1000)
            let font = UIFont.systemFont(ofSize: 16)
            cell.bubbleWidthAnchor?.constant = message.text.estimateFrame(for: estimatedSize, with: font).width + 30
            if message.sender == UserController.shared.currentUser!.identifier! {
                // Outgoing message
                cell.bubbleView.backgroundColor = Constants.data.lightBlue
                cell.nameLabel.isHidden = true
                cell.textView.textColor = UIColor.white
                cell.textViewTopAnchor?.constant = 0
                cell.bubbleViewRightAnchor?.isActive = true
                cell.bubbleViewLeftAnchor?.isActive = false
                if message.read {
                    cell.readLabel.isHidden = false
                } else {
                    cell.readLabel.isHidden = true
                }
                cell.profileImageView.isHidden = true
            } else {
                // Incoming message
                if self.course != nil, let user = self.users?[indexPath.item] {
                    cell.textViewTopAnchor?.constant = 15
                    cell.nameLabel.text = user.name
                    cell.nameLabel.isHidden = false
                    let requiredWidth = cell.nameLabel.requiredWidth() + 28
                    if cell.bubbleWidthAnchor!.constant < requiredWidth {
                        cell.bubbleWidthAnchor!.constant = requiredWidth
                    }
                } else {
                    cell.nameLabel.isHidden = true
                }
                cell.bubbleView.backgroundColor = UIColor.white
                cell.textView.textColor = UIColor.black
                cell.bubbleViewRightAnchor?.isActive = false
                cell.bubbleViewLeftAnchor?.isActive = true
                cell.readLabel.isHidden = true
                cell.profileImageView.isHidden = false
                cell.profileImageView.loadImageWithIdentifier(message.sender)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = CGSize(width: UIScreen.main.bounds.width, height: 80)
        
        if let message = self.messages?[indexPath.item] {
            let estimatedSize = CGSize(width: 200, height: 1000)
            let font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
            if message.sender == UserController.shared.currentUser!.identifier! {
                size.height = message.text.estimateFrame(for: estimatedSize, with: font).height + 20
            } else {
                var nameHeight: CGFloat = 0
                if self.course != nil {
                    nameHeight = 15
                } else {
                    nameHeight = 0
                }
                size.height = message.text.estimateFrame(for: estimatedSize, with: font).height + 20 + nameHeight
            }
        }
        
        return size
    }

}

extension ChatViewController {
    
    fileprivate func subtitleTitleView(subtitle: String) -> UIView {
        var title = String()
        if let user = self.user {
            title = user.name
        } else if let course = self.course {
            title = Constants.data.subjects[course.subject]!
        } else {
            title = "Chat"
        }
        let titleLabel = UILabel(frame: CGRect(x: 0, y: -5, width: 0, height: 0))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
        titleLabel.text = title
        titleLabel.sizeToFit()
        
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor.white
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightLight)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height: 35))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showProfile))
        tap.cancelsTouchesInView = false
        titleView.addGestureRecognizer(tap)
        
        let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width
        
        if widthDiff < 0 {
            let newX = widthDiff / 2
            subtitleLabel.frame.origin.x = abs(newX)
        } else {
            let newX = widthDiff / 2
            titleLabel.frame.origin.x = newX
        }
        
        return titleView
    }
    
}
