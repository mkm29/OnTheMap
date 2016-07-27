//
//  StudentManager.swift
//  on-the-map
//
//  Created by Mitchell Murphy on 7/19/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

import Foundation
import CoreLocation

class StudentManager {
    
    var students = [Student]()
    var currentStudent: Student?
    var studentPlacemark: CLPlacemark?
    
    let udacityClient = UdacityClient.sharedInstance
    let parseClient = ParseClient.sharedInstance
    
    
    // MARK: - currentStudent methods
    
    func updateCurrentStudent(studentInfo: [String:String]) {
        if currentStudent != nil {
            if let mapString = studentInfo["mapString"] {
                currentStudent!.mapString = mapString
            }
            if let mediaURL = studentInfo["mediaURL"] {
                currentStudent!.mediaURL = mediaURL
            }
        }
    }
    
    func setStudentAttributes(studentInfo: [String:String], placemark: CLPlacemark?) {
        if currentStudent != nil {
            
            if let mapString = studentInfo["mapString"] {
                currentStudent!.mapString = mapString
            }
            if let mediaURL = studentInfo["mediaURL"] {
                currentStudent!.mediaURL = mediaURL
            }
            
            if let placemark = placemark {
                studentPlacemark = placemark
                if let lat = placemark.location?.coordinate.latitude {
                    currentStudent?.latitude = lat
                }
                if let long = placemark.location?.coordinate.longitude {
                    currentStudent?.longitude = long
                }
            }
        }
    }
    
    func setObjectId(objectId: String) {
        if currentStudent != nil {
            currentStudent!.objectId = objectId
        }
    }
    
    class var sharedInstance: StudentManager {
        struct Static {
            static let instance: StudentManager = StudentManager()
        }
        return Static.instance
    }
}