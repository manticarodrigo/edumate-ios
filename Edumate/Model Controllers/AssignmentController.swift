//
//  AssignmentController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/31/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation
import UIKit

class AssignmentController {
    
    static func assignmentWithIdentifier(_ identifier: String, completion: @escaping (_ assignment: Assignment?) -> Void) {
        FirebaseController.dataAtEndpoint("/assignments/\(identifier)") { (data) -> Void in
            if let data = data as? [String: AnyObject] {
                let assignment = Assignment(json: data, identifier: identifier)
                completion(assignment)
            } else {
                completion(nil)
            }
        }
    }
    
    static func assignmentsForUser(_ user: User, completion: @escaping (_ assignments: [Assignment]?) -> Void) {
        assignmentsByUser(user) { (ownedAssignments) in
            if let ownedAssignments = ownedAssignments {
                courseAssignmentsForUser(user, completion: { (courseAssignments) in
                    if let courseAssignments = courseAssignments {
                        var userAssignments = [Assignment]()
                        for courseAssignment in courseAssignments {
                            if courseAssignment.admin != UserController.shared.currentUser.identifier {
                                userAssignments.append(courseAssignment)
                            }
                        }
                        for ownedAssignment in ownedAssignments {
                            userAssignments.append(ownedAssignment)
                        }
                        let orderedAssigments = orderAssignments(userAssignments)
                        completion(orderedAssigments)
                    } else {
                        let orderedAssigments = orderAssignments(ownedAssignments)
                        completion(orderedAssigments)
                    }
                })
            } else {
                courseAssignmentsForUser(user, completion: { (courseAssignments) in
                    if let courseAssignments = courseAssignments {
                        let orderedAssigments = orderAssignments(courseAssignments)
                        completion(orderedAssigments)
                    } else {
                        completion(nil)
                    }
                })
            }
        }
    }
    
    static func assignmentsByUser(_ user: User, completion: @escaping (_ assignments: [Assignment]?) -> Void) {
        FirebaseController.base.child("/assignments").queryOrdered(byChild: "admin").queryEqual(toValue: UserController.shared.currentUser.identifier!).observe(.value, with: { snapshot in
            if let assignmentDictionaries = snapshot.value as? [String: AnyObject] {
                var assignments = [Assignment]()
                for key in assignmentDictionaries.keys {
                    let data = assignmentDictionaries[key]
                    let name = data?["name"] as! String
                    let description = data?["description"] as? String
                    let dueDate = data?["dueDate"] as! NSNumber
                    let admin = data?["admin"] as! String
                    let course = data?["course"] as? String
                    let assignment = Assignment(name: name, description: description, dueDate: dueDate, admin: admin, course: course, identifier: key)
                    assignments.append(assignment)
                }
                // let assignments = assignmentDictionaries.flatMap({Assignment(json: $0.1 as! [String : AnyObject], identifier: $0.0)})
                completion(assignments)
            } else {
                completion(nil)
            }
        })
    }
    
    static func courseAssignmentsForUser(_ user: User, completion: @escaping (_ assignments: [Assignment]?) -> Void) {
        CourseController.coursesForUser(user) { (courses) in
            if let courses = courses {
                var assignmentArray = [Assignment]()
                for course in courses {
                    assignmentsForCourse(course, completion: { (assignments) in
                        if let assignments = assignments {
                            for assignment in assignments {
                                assignmentArray.append(assignment)
                            }
                            completion(assignmentArray)
                        } else {
                            completion(nil)
                        }
                    })
                }
            } else {
                completion(nil)
            }
        }
    }
    
    
    static func assignmentsForCourse(_ course: Course, completion: @escaping (_ assignments: [Assignment]?) -> Void) {
        FirebaseController.base.child("/assignments/").queryOrdered(byChild: "course").queryEqual(toValue: course.identifier!).observe(.value, with: { snapshot in
            if let assignmentDictionaries = snapshot.value as? [String: AnyObject] {
                var assignments = [Assignment]()
                for key in assignmentDictionaries.keys {
                    let data = assignmentDictionaries[key]
                    let name = data?["name"] as! String
                    let description = data?["description"] as? String
                    let dueDate = data?["dueDate"] as! NSNumber
                    let admin = data?["admin"] as! String
                    let course = data?["course"] as? String
                    let assignment = Assignment(name: name, description: description, dueDate: dueDate, admin: admin, course: course, identifier: key)
                    assignments.append(assignment)
                }
                completion(assignments)
            } else {
                completion(nil)
            }

        })
    }
    
    static func courseForAssignment(_ assignment: Assignment, completion: @escaping (_ course: Course?) -> Void) {
        if let courseIdentifier = assignment.course {
            FirebaseController.dataAtEndpoint("/courses/\(courseIdentifier)/") { (data) -> Void in
                if let json = data as? [String: AnyObject] {
                    let course = Course(json: json, identifier: assignment.course!)
                    completion(course)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    static func orderAssignments(_ assignments: [Assignment]) -> [Assignment] {
        return assignments.sorted(by: {TimeInterval($0.0.dueDate) > TimeInterval($0.1.dueDate)})
    }
    
}
