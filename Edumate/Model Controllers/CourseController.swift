//
//  CourseController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/23/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation
import UIKit

class CourseController {
    
    static func createCourse(_ course: Course, completion: @escaping (_ course: Course?) -> Void) {
        let endpointBase = FirebaseController.base.child("courses").childByAutoId()
        let identifier = endpointBase.key
        var newCourse = course
        newCourse.identifier = identifier
        self.addUserToCourse(UserController.shared.currentUser, course: newCourse, completion: { (success) in
            if success {
                newCourse.save()
                self.courseWithIdentifier(identifier, completion: { (course) in
                    if let course = course {
                        completion(course)
                    
                    } else {
                        completion(nil)
                    }
                })
            } else {
                completion(nil)
            }
        })
    }
    
    static func courseWithIdentifier(_ identifier: String, completion: @escaping (_ course: Course?) -> Void) {
        FirebaseController.dataAtEndpoint("/courses/\(identifier)") { (data) -> Void in
            if let data = data as? [String: AnyObject] {
                let course = Course(json: data, identifier: identifier)
                completion(course)
            } else {
                completion(nil)
            }
        }
    }
    
    static func observeAllCourses(_ completion: @escaping (_ courses: [Course]?) -> Void) {
        FirebaseController.observeDataAtEndpoint("/courses") { (data) -> Void in
            if let json = data as? [String: AnyObject] {
                let courses = json.flatMap({Course(json: $0.1 as! [String : AnyObject], identifier: $0.0)})
                completion(courses)
            } else {
                completion(nil)
            }
        }
    }
    
    static func fetchNewestCourses(_ completion: @escaping (_ courses: [Course]?) -> Void) {
        FirebaseController.base.child("/courses").queryLimited(toFirst: 50).observeSingleEvent(of: .value, with: { snapshot in
            if let json = snapshot.value as? [String: AnyObject] {
                let courses = json.flatMap({Course(json: $0.1 as! [String : AnyObject], identifier: $0.0)})
                completion(courses)
            } else {
                completion(nil)
            }
        })
    }
    
    static func coursesForUser(_ user: User, completion: @escaping (_ courses: [Course]?) -> Void) {
        FirebaseController.base.child("/courses").queryOrdered(byChild: "/users/\(user.identifier!)").queryEqual(toValue: true).observe(.value, with: { data in
            if let json = data.value as? [String: AnyObject] {
                let courses = json.flatMap({Course(json: $0.1 as! [String : AnyObject], identifier: $0.0)})
                completion(courses)
            } else {
                completion(nil)
            }
        })
    }
    
    static func usersForCourse(_ course: Course, completion: @escaping (_ users: [User]?) -> Void ) {
        FirebaseController.dataAtEndpoint("/courses/\(course.identifier!)/users/") { (data) -> Void in
            if let json = data as? [String: AnyObject] {
                var users: [User] = []
                var objectCount = 0
                for userJson in json {
                    UserController.userWithIdentifier(userJson.0, completion: { (user) -> Void in
                        if let user = user {
                            users.append(user)
                            objectCount += 1
                            if objectCount == json.count {
                                completion(users)
                            }
                        } else {
                            objectCount += 1
                            if objectCount == json.count {
                                if users.count > 0 {
                                    completion(users)
                                } else {
                                    completion(nil)
                                }
                            }
                        }
                    })
                }
            } else {
                completion(nil)
            }
        }
    }
    
    static func userJoined(_ user: User, course: Course, completion: @escaping (_ joined: Bool) -> Void ) {
        FirebaseController.dataAtEndpoint("/courses/\(course.identifier!)/users/\(user.identifier!)") { (data) -> Void in
            if let _ = data {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    static func addUserToCourse(_ user: User, course: Course, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/courses/\(course.identifier!)/users/\(user.identifier!)").setValue(true)
        completion(true)
    }
    
    static func removeUserFromCourse(_ user: User, course: Course, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/courses/\(course.identifier!)/users/\(user.identifier!)").removeValue()
        completion(true)
    }
    
    static func addAssignmentToCourse(_ assignment: Assignment, course: Course, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/courses/\(course.identifier!)/assignments/\(assignment.identifier!)").setValue(true)
        completion(true)
    }
    
    static func removeAssignmentFromCourse(_ assignment: Assignment, course: Course, completion: (_ success: Bool) -> Void) {
        FirebaseController.base.child("/courses/\(course.identifier!)/assignments/\(assignment.identifier!)").removeValue()
        completion(true)
    }
    
}
