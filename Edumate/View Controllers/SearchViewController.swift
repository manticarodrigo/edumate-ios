//
//  SearchViewController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 2/28/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit
import CoreLocation
import GeoFire

class SearchViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, SearchTextFieldDelegate {
    
    @IBOutlet weak var searchTextField: SearchTextField!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    fileprivate var cardFrame: CGRect!
    
    fileprivate var allCards: [DraggableView]!
    fileprivate var loadedCards: [DraggableView]!
    fileprivate var cardsLoadedIndex: Int!
    
    // MARK: - View Methods
    
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
        // Setup card frame
        self.cardFrame = CGRect(x: 10,
                                y: 10,
                                width: frame.width - 20,
                                height: frame.height - 90)
        // Setup search text field
        self.searchTextField.delegate = self
        self.searchTextField.searchDelegate = self
        self.searchTextField.popoverSize = CGRect(x: 0, y: navBarHeight, width: screen.width, height: frame.height)
        // Setup reload button
        self.reloadButton.stylize()
        self.reloadButton.addTarget(self, action: #selector(self.beginSearch), for: .touchUpInside)
        // Setup follow reloadButton
        self.followButton.stylize()
        self.followButton.layer.cornerRadius = self.followButton.frame.size.height/2
        self.followButton.addTarget(self, action: #selector(self.swipeDown), for: .touchUpInside)
        // Setup left dismiss button
        self.leftButton.stylize()
        self.leftButton.addTarget(self, action: #selector(self.swipeLeft), for: .touchUpInside)
        // Setup right dismiss button
        self.rightButton.stylize()
        self.rightButton.addTarget(self, action: #selector(self.swipeRight), for: .touchUpInside)
        // Setup location manager
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // Add gesture to hide keyboard
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.beginSearch()
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

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let user = sender as? User {
            let nav = segue.destination as! UINavigationController
            let profileVc = nav.topViewController as! ProfileViewController
            profileVc.user = user
        }
    }
    
    // MARK: - Location Delegate
    
    func requestLocation() {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined:
                // Ask for authorization from the user to get location
                self.locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                // Direct users to settings to enable location services
                self.displayAlert("Location Disabled", message: "Navigate to your device's settings page and scroll down to the Edumate app to enable location services.")
            case .authorizedAlways, .authorizedWhenInUse:
                // Request location
                self.currentLocation = nil
                self.locationManager.requestLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location {
            if self.currentLocation == nil {
                print("lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude)")
                self.currentLocation = location
                self.findNearbyUsers()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    // MARK: - GeoFire Methods

    func findNearbyUsers() {
        var nearbyIds = [String]()
        // Update user's current location
        let geoFire = GeoFire(firebaseRef: FirebaseController.base.child("locations"))
        if let currentUser = UserController.shared.currentUser, let currentLocation = self.currentLocation {
            geoFire!.setLocation(currentLocation, forKey: currentUser.identifier!)
        }
        // Query locations at currentLocation with user's radius times 1.60934 meters or 1 mile
        var radiusInt = 25
        DefaultsController.fetchRadiusInt { (radius) in
            if let radius = radius {
                radiusInt = radius
            } else {
                DefaultsController.setRadiusInt(int: 25)
            }
        }
        let circleQuery = geoFire?.query(at: self.currentLocation, withRadius: Double(radiusInt) * 1.60934)
        // Observe users within range and add them to userArray
        circleQuery?.observe(.keyEntered, with: { (identifier, location) in
            if let currentUser = UserController.shared.currentUser {
                if identifier != currentUser.identifier! {
                    nearbyIds.append(identifier!)
                }
            }
        })
        // Fire when query has finished
        circleQuery?.observeReady({
            if nearbyIds.count > 0 {
                print("found \(nearbyIds.count) users nearby.")
                var users = [User]()
                var courses = [[Course]]()
                var nearbyCount = 0
                for identifier in nearbyIds {
                    UserController.userWithIdentifier(identifier, completion: { (user) in
                        if let user = user {
                            UserController.userFollows(UserController.shared.currentUser, followsUser: user, completion: { (follows) in
                                if follows == false {
                                    self.coursesForUser(user, completion: { (matchingCourses) in
                                        if let matchingCourses = matchingCourses {
                                            print("\(user.firstName()) has \(matchingCourses.count) matching courses.")
                                            users.append(user)
                                            courses.append(matchingCourses)
                                            nearbyCount += 1
                                            if nearbyCount == nearbyIds.count {
                                                self.createCards(users, courses: courses)
                                            }
                                        } else {
                                            nearbyCount += 1
                                            if nearbyCount == nearbyIds.count {
                                                self.createCards(users, courses: courses)
                                            }
                                        }
                                    })
                                } else {
                                    nearbyCount += 1
                                    if nearbyCount == nearbyIds.count {
                                        self.createCards(users, courses: courses)
                                    }
                                }
                            })
                        } else {
                            nearbyCount += 1
                            if nearbyCount == nearbyIds.count {
                                self.createCards(users, courses: courses)
                            }
                        }
                    })
                }
            }
        })
    }
    
    // MARK: - Draggable View Delegate
    
    func beginSearch() {
        // Reset cards
        self.loadCards(cards: [])
        // Check if no subject selected
        DefaultsController.fetchSubjectInt { (subjectInt) in
            if subjectInt != nil {
                self.requestLocation()
            } else {
                self.performSegue(withIdentifier: "filter", sender: self)
            }
        }
    }
    
    func createCards(_ users: [User], courses: [[Course]]) {
        print("creating \(users.count) cards...")
        DefaultsController.fetchSubjectInt { (subjectInt) in
            if let subjectInt = subjectInt {
                var cards = [DraggableView]()
                var userCount = 0
                for user in users {
                    UserController.userTutors(user, subject: subjectInt) { (tutors) in
                        var tutorBool = false
                        if tutors {
                            tutorBool = true
                        }
                        let newCard: DraggableView = self.createDraggableViewForUserWithCourses(user, tutors: tutorBool, courses: courses[userCount])
                        cards.append(newCard)
                        userCount += 1
                        if userCount == users.count {
                            self.loadCards(cards: cards)
                        }
                    }
                }
            }
        }
    }
    
    func loadCards(cards: [DraggableView]) {
        print("loading \(cards.count) cards...")
        self.allCards = cards
        self.loadedCards = []
        self.cardsLoadedIndex = 0
        for view in self.view.subviews {
            if view.isKind(of: DraggableView.self) {
                view.removeFromSuperview()
            }
        }
        DefaultsController.fetchIntroBool { (done) in
            if let done = done {
                if done == false {
                    let introCards = self.introCards()
                    var index = 0
                    for card in introCards {
                        self.allCards.insert(card, at: index)
                        index += 1
                    }
                }
            } else {
                let introCards = self.introCards()
                var index = 0
                for card in introCards {
                    self.allCards.insert(card, at: index)
                    index += 1
                }
            }
        }
        
        if self.allCards.count > 0 {
            let numLoadedCardsCap = min(self.allCards.count, 2)
            for i in 0 ..< self.allCards.count {
                if i < numLoadedCardsCap {
                    self.loadedCards.append(self.allCards[i])
                }
            }
            
            for i in 0 ..< self.loadedCards.count {
                if i > 0 {
                    self.view.insertSubview(self.loadedCards[i], belowSubview: self.loadedCards[i - 1])
                } else {
                    self.view.addSubview(self.loadedCards[i])
                }
                self.cardsLoadedIndex = self.cardsLoadedIndex + 1
            }
        }
    }
    
    func swipeRight() {
        if self.loadedCards.count > 0 {
            let dragView: DraggableView = self.loadedCards[0]
            dragView.completeSwipeRight()
        }
    }
    
    func swipeLeft() {
        if self.loadedCards.count > 0 {
            let dragView: DraggableView = self.loadedCards[0]
            dragView.completeSwipeLeft()
        }
    }
    
    func swipeDown() {
        if self.loadedCards.count > 0 {
            let dragView: DraggableView = self.loadedCards[0]
            dragView.completeSwipeDown()
        }
    }
    
}

extension SearchViewController : DraggableViewDelegate {
    
    func cardSwipedLeft(_ card: UIView) {
        self.loadAnotherCard()
    }
    
    func cardSwipedRight(_ card: UIView) {
        self.loadAnotherCard()
    }
    
    func cardSwipedUp(_ card: UIView) {
        self.loadAnotherCard()
    }
    
    func cardSwipedDown(_ card: UIView) {
        print(self.loadedCards.count)
        if let user = self.loadedCards[0].user {
            print(user.name)
            UserController.follow(user, completion: { (success) in
                if success {
                    DefaultsController.fetchIntroBool(completion: { (done) in
                        if done == nil || done == false {
                            let alertController = UIAlertController(title: "Success!", message: "You are now following \(user.firstName()).", preferredStyle: .alert)
                            let doneAction = UIAlertAction(title: "Don't show again.", style: .destructive) { (_) -> Void in
                                DefaultsController.setIntroBool(bool: true)
                            }
                            let profileAction = UIAlertAction(title: "Go to profile", style: .default) { (_) -> Void in
                                self.performSegue(withIdentifier: "profile", sender: user)
                            }
                            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                            alertController.addAction(doneAction)
                            alertController.addAction(profileAction)
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                            alertController.view.tintColor = Constants.data.lightBlue
                        }
                    })
                }
            })
        }
        self.loadAnotherCard()
    }
    
    fileprivate func loadAnotherCard() {
        if self.loadedCards.count > 0 {
            self.loadedCards.remove(at: 0)
            if self.cardsLoadedIndex < self.allCards.count {
                let nextCard = self.allCards[self.cardsLoadedIndex]
                self.loadedCards.append(nextCard)
                self.cardsLoadedIndex = self.cardsLoadedIndex + 1
                self.view.insertSubview(nextCard, belowSubview: self.loadedCards[self.loadedCards.count - 2])
            }
        }
    }
    
    fileprivate func matchingCoursesString(for courses: [Course]) -> String {
        var subject = Int()
        DefaultsController.fetchSubjectInt { (subjectInt) in
            if let subjectInt = subjectInt {
                subject = subjectInt
            } else {
                self.performSegue(withIdentifier: "filter", sender: self)
            }
        }
        var courseString = String()
        let matchingCourses = courses.filter({$0.subject == subject})
        for course in matchingCourses {
            if course == matchingCourses.last {
                courseString += "\(course.name)."
            } else {
                courseString += "\(course.name), "
            }
        }
        return courseString
    }
    
    fileprivate func introCards() -> [DraggableView] {
        let frame = self.cardFrame!
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let subtitleAttributes = [NSFontAttributeName : UIFont.systemFont(ofSize: 25, weight: UIFontWeightBold), NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : UIColor.black]
        let textAttributes = [NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium), NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : UIColor.darkGray]
        var subject = String()
        DefaultsController.fetchSubjectInt { (subjectInt) in
            if let subjectInt = subjectInt {
                subject = Constants.data.subjects[subjectInt]!
            } else {
                self.performSegue(withIdentifier: "filter", sender: self)
            }
        }
        var cards = [DraggableView]()
        // First card
        let welcomeSubtitle = NSAttributedString(string: "WELCOME", attributes: subtitleAttributes)
        let welcomeImage = UIImage(named: "intro1.png")!
        let welcomeText = "Swipe anywhere to continue."
        let welcomeAttrString = NSMutableAttributedString(string: welcomeText, attributes: textAttributes)
        let welcomeCard = DraggableView(frame: frame,
                                  title: "",
                                  subtitle: welcomeSubtitle,
                                  image: welcomeImage,
                                  tutors: false,
                                  text: welcomeAttrString,
                                  user: nil,
                                  delegate: self)
        cards.append(welcomeCard)
        // Second card
        let followSubtitle = NSAttributedString(string: "FOLLOWING", attributes: subtitleAttributes)
        let followText = "You selected \(subject). People in relevant courses will appear in these cards."
        let subjectRange = (followText as NSString).range(of: subject)
        let followAttrString = NSMutableAttributedString(string: followText, attributes: textAttributes)
        followAttrString.addAttribute(NSForegroundColorAttributeName, value: Constants.data.lightGreen , range: subjectRange)
        let followCard = DraggableView(frame: frame,
                                  title: "",
                                  subtitle: followSubtitle,
                                  image: UIImage(named: "intro2.png")!,
                                  tutors: false,
                                  text: followAttrString,
                                  user: nil,
                                  delegate: self)
        cards.append(followCard)
        // Third card
        let tutorSubtitle = NSAttributedString(string: "TUTORING", attributes: subtitleAttributes)
        let tutorImage = UIImage(named: "intro3.png")!
        let tutorText = "The tutor label indicates a person offering \(subject) tutoring. Send a message if you need their help."
        let subjectRange2 = (tutorText as NSString).range(of: subject)
        let tutorAttrString = NSMutableAttributedString(string: tutorText, attributes: textAttributes)
        tutorAttrString.addAttribute(NSForegroundColorAttributeName, value: Constants.data.lightGreen , range: subjectRange2)
        let tutorCard = DraggableView(frame: frame,
                                  title: "",
                                  subtitle: tutorSubtitle,
                                  image: tutorImage,
                                  tutors: true,
                                  text: tutorAttrString,
                                  user: nil,
                                  delegate: self)
        cards.append(tutorCard)
        
        return cards
    }
    
    func coursesForUser(_ user: User, completion: @escaping (_ courses: [Course]?) -> Void) {
        CourseController.coursesForUser(user) { (courses) in
            if let courses = courses {
                var matchingCourses = [Course]()
                for course in courses {
                    let subjectKey = course.subject
                    DefaultsController.fetchSubjectInt(completion: { (subjectInt) in
                        if let subjectInt = subjectInt {
                            if subjectKey == subjectInt {
                                matchingCourses.append(course)
                            }
                        }
                    })
                }
                if matchingCourses.count > 0 {
                    UserController.userWithIdentifier(user.identifier!, completion: { (user) in
                        if let user = user {
                            DefaultsController.fetchTutorBool(completion: { (tutors) in
                                if let tutors = tutors {
                                    if tutors {
                                        DefaultsController.fetchSchoolBool(completion: { (restricted) in
                                            if let restricted = restricted {
                                                if restricted {
                                                    if user.university == UserController.shared.currentUser.university {
                                                        completion(courses)
                                                    }
                                                } else {
                                                    completion(courses)
                                                }
                                            } else {
                                                completion(courses)
                                            }
                                        })
                                    } else {
                                        completion(nil)
                                    }
                                } else {
                                    DefaultsController.fetchSchoolBool(completion: { (restricted) in
                                        if let restricted = restricted {
                                            if restricted {
                                                if user.university == UserController.shared.currentUser.university {
                                                    completion(courses)
                                                }
                                            } else {
                                                completion(courses)
                                            }
                                        } else {
                                            completion(courses)
                                        }
                                    })
                                }
                            })
                        }
                    })
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    fileprivate func createDraggableViewForUserWithCourses(_ user: User, tutors: Bool, courses: [Course]) -> DraggableView {
        let frame = self.cardFrame!
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let subtitle = NSAttributedString(string: user.university ?? "", attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightSemibold), NSParagraphStyleAttributeName : paragraphStyle])
        let attrText = NSMutableAttributedString(string: self.matchingCoursesString(for: courses), attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium), NSParagraphStyleAttributeName : paragraphStyle])
        let draggableView = DraggableView(frame: frame,
                                          title: user.name,
                                          subtitle: subtitle,
                                          image: UIImage(named: "user-placeholder.png")!,
                                          tutors: tutors,
                                          text: attrText,
                                          user: user,
                                          delegate: self)
        draggableView.imageView.loadImageWithIdentifier(user.identifier!)
        
        return draggableView
    }
    
}
