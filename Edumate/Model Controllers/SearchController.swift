//
//  SearchController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 11/11/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation

class SearchController {
    
    static func observeUsers() {
        UserController.observeAllUsers { (users) in
            if let users = users {
                var dictArray = [NSDictionary]()
                for user in users {
                    let dictionary = ["Text": user.name,"detailText": user.university, "User": user] as NSDictionary
                    dictArray.append(dictionary)
                }
                Constants.data.userData = dictArray
            } else {
                Constants.data.userData = nil
            }
        }
    }
    
    static func observeCourses() {
        CourseController.observeAllCourses { (courses) in
            if let courses = courses {
                var dictArray = [NSDictionary]()
                for course in courses {
                    let dictionary = ["Text": course.name,"detailText": course.university, "Course": course] as NSDictionary
                    dictArray.append(dictionary)
                }
                Constants.data.courseData = dictArray
            } else {
                Constants.data.courseData = nil
            }
        }
    }
    
    static func generateUniversities() {
        let dataPath = Bundle.main.path(forResource: "us_university_data", ofType: "json")
        let data = try? Data.init(contentsOf: URL(fileURLWithPath: dataPath!))
        var contents = [AnyObject]()
        do {
            contents = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [AnyObject]
        } catch {
            print(error)
        }
        var dictArray = [NSDictionary]()
        for i in 0...contents.count-1 {
            let universityName = contents[i]["university"] as! String
            let dictionary = ["Text": universityName] as NSDictionary
            dictArray.append(dictionary)
        }
        Constants.data.universityData = dictArray
    }
    
    static func stopObservingUsers() {
        FirebaseController.base.child("users").removeAllObservers()
    }
    
    static func stopObservingCourses() {
        FirebaseController.base.child("courses").removeAllObservers()
    }
    
}
