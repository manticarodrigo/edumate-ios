//
//  Constants.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/23/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

class Constants {
    static let data = Constants()
    
    let lightBlue:UIColor = Helper.hexStringToUIColor(hex: "0D99FC")
    let darkBlue:UIColor = Helper.hexStringToUIColor(hex: "0288D1")
    let lightGreen:UIColor = Helper.hexStringToUIColor(hex: "4FD689")
    let fadedRed:UIColor = Helper.hexStringToUIColor(hex: "FF5252")
    
    let seasons = ["Fall", "Spring", "Summer"]
    let years = ["2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023", "2024", "2025", "2026", "2027", "2028", "2029", "2030"]
    
    let subjects = [0: "Accounting", 1 : "Agriculture", 2 : "Anatomy", 3 : "Anthropology", 4 : "Archaeology", 5 : "Architecture", 6: "Astronomy", 7: "Astrophysics",  8: "Biology", 9 : "Business", 10 : "Chemistry", 11 : "Communications", 12 : "Computer Science", 13 : "Design", 14 : "Earth Sciences", 15 : "Economics", 16 : "Education", 17 : "Engineering", 18 : "Environmental Studies", 19 : "Ethnic Studies", 20 : "Finance", 21 : "Gender Studies", 22 : "Geography", 23 : "History", 24 : "Journalism", 25 : "Law", 26 : "Linguistics", 27 : "Literature", 28 : "Logic", 29 : "Marketing", 30 : "Mathematics", 31 : "Medicine", 32 : "Nutrition", 33 : "Organizational Studies", 34 : "Performing Arts", 35 : "Philosophy", 36 : "Physics", 37 : "Political Science", 38 : "Psychology", 39 : "Public Administration", 40 : "Religion", 41 : "Sociology", 42 : "Space Science", 43 : "Sports", 44 : "Statistics", 45 : "Systems Science", 46 : "Visual Arts"]
    
    var userData: [NSDictionary]!
    var courseData: [NSDictionary]!
    var universityData: [NSDictionary]!
    
}

extension Constants {
    func hexStringToUIColor(hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
