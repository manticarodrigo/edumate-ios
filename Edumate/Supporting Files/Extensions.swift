//
//  Extensions.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 8/30/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import UIKit

let cache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageWithIdentifier(_ identifier: String) {
        self.image = UIImage(named: "user-placeholder.png")
        let activityIndicator = self.addActivityIndicator()
        // Check cache for image first
        if let cachedImage = cache.object(forKey: identifier as AnyObject) as? UIImage {
            self.image = cachedImage
            activityIndicator.stopAnimating()
            return
        } else {
            // Otherwise start download
            ImageController.imageForIdentifier(identifier) { (image) in
                if let downloadedImage = image {
                    cache.setObject(downloadedImage, forKey: identifier as AnyObject)
                    self.image = downloadedImage
                    activityIndicator.stopAnimating()
                    return
                } else {
                    activityIndicator.stopAnimating()
                    return
                }
            }
        }
    }
    
    func addActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        activityIndicator.backgroundColor = UIColor.clear
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = .white
        self.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        return activityIndicator
    }
    
}

extension UIImage {
    
    func scaledToSize(size:CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        self.draw(in:CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func compressedData() -> Data {
        var compressionQuality: CGFloat = 0.7 // 30% compression
        var actualHeight: CGFloat = self.size.height
        var actualWidth: CGFloat = self.size.width
        var imgRatio: CGFloat = actualWidth/actualHeight
        let maxHeight: CGFloat = 1034.0
        let maxWidth: CGFloat = 1034.0
        let maxRatio: CGFloat = maxWidth/maxHeight
        if (actualHeight > maxHeight || actualWidth > maxWidth) {
            if(imgRatio < maxRatio) {
                // Adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            } else if(imgRatio > maxRatio) {
                // Adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            } else {
                actualHeight = maxHeight
                actualWidth = maxWidth
                compressionQuality = 1
            }
        }
        let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        self.draw(in: rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        let data = UIImageJPEGRepresentation(img!, compressionQuality)
        
        return data!
    }
    
    func createSelectionIndicator(color: UIColor, size: CGSize, lineWidth: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(x: 0, y: size.height - lineWidth, width: size.width, height: lineWidth))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func withColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()
        
        let context = UIGraphicsGetCurrentContext()! as CGContext
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0);
        context.setBlendMode(.normal)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: self.cgImage!)
        context.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
}

extension UIViewController: UINavigationControllerDelegate {
    
    func stylizeNavBar() {
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    func displayAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        alert.view.tintColor = Constants.data.lightBlue
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        // self.view.endEditing(true)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
    }
    
}

extension UIView {
    
    func addDropShadow() {
        self.layer.shadowRadius = 3
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
    }
    
}

extension UIButton {
    
    func stylize() {
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        self.setBackgroundColor(self.backgroundColor!.darker(), forState: .highlighted)
    }
    
    func setBackgroundColor(_ color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()?.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: forState)
    }
    
}

extension UIColor {
    
    func lighter(_ amount : CGFloat = 0.20) -> UIColor {
        return hueColorWithBrightnessAmount(1 + amount)
    }
    
    func darker(_ amount : CGFloat = 0.20) -> UIColor {
        return hueColorWithBrightnessAmount(1 - amount)
    }
    
    fileprivate func hueColorWithBrightnessAmount(_ amount: CGFloat) -> UIColor {
        var hue         : CGFloat = 0
        var saturation  : CGFloat = 0
        var brightness  : CGFloat = 0
        var alpha       : CGFloat = 0
        
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return UIColor( hue: hue,
                        saturation: saturation,
                        brightness: brightness * amount,
                        alpha: alpha )
    }
    
}

extension Date {
    
    func timeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let timeString = dateFormatter.string(from: self)
        return timeString
    }
    
    func dayOfWeek() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).capitalized
    }
    
    func shortMonthDayYearHour() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: self)
        return dateString
    }
    
    func monthDayYearHour() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: self)
        return dateString
    }
    
    func monthDayYear() -> String {
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: self)
        let year =  components.year!
        let month = components.month!
        let day = components.day!
        return "\(month) \(day), \(year)"
    }
    
}

extension UILabel {
    
    func requiredWidth() -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: self.frame.height))
        label.numberOfLines = 1
        label.font = self.font
        label.text = self.text
        label.sizeToFit()
        return label.frame.width
    }
    
    func requiredHeight() -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = self.font
        label.text = self.text
        label.sizeToFit()
        return label.frame.height
    }
    
}

extension String {
    
    func estimateFrame(for size: CGSize, with font: UIFont) -> CGRect {
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: self).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: font], context: nil)
    }
    
}

extension NSMutableAttributedString {
    convenience init?(string : String, font : UIFont, maxWidth : CGFloat){
        self.init()
        for size in stride(from: font.pointSize, to: 1, by: -1)  {
            let attrs = [NSFontAttributeName : font.withSize(size)]
            let attrString = NSAttributedString(string: string, attributes: attrs)
            if attrString.size().width <= maxWidth {
                self.setAttributedString(attrString)
                return
            }
        }
        return nil
    }
}

public func += ( left: inout NSMutableAttributedString, right: NSAttributedString) {
    left.append(right)
}

public func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    let result  = NSMutableAttributedString(attributedString: right)
    result.append(right)
    return result
}

public func + (left: NSAttributedString, right: String) -> NSAttributedString {
    let result  = NSMutableAttributedString(attributedString: left)
    result.append(NSAttributedString(string: right))
    return result
}
