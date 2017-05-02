//
//  ImageController.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 7/23/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation
import UIKit

class ImageController {
    
    static let base = FirebaseController.storage
    
    static func imageForIdentifier(_ identifier: String, completion: @escaping (_ image: UIImage?) -> Void) {
        print("Storage fetching image for user with id \(identifier)")
        let baseForEndpoint = ImageController.base.child("/\(identifier)/image.jpg")
        baseForEndpoint.data(withMaxSize: 1 * 1024 * 1024) { (data, error) -> Void in
            if let error = error {
                print("Storage returned error \(error)")
                completion(nil)
            } else {
                let image = UIImage(data: data!)
                print("Storage returned image \(image!)")
                completion(image)
            }
        }
    }
    
    static func uploadImageForIdentifier(_ identifier: String, image: UIImage, completion: @escaping (_ image: UIImage?) -> Void) {
        print("Storage uploading image for user with id \(identifier)")
        let baseForEndPoint = ImageController.base.child("/\(identifier)/image.jpg")
        let data = image.compressedData()
        baseForEndPoint.put(data as Data, metadata: nil) { metadata, error in
            if let error = error {
                print("Storage returned error \(error)")
                completion(nil)
            } else {
                let image = UIImage(data: data as Data)
                print("Storage returned image \(image!)")
                completion(image)
            }
        }
    }
    
}
