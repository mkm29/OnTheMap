//
//  Student.swift
//  On The Map
//
//  Created by Mitchell Murphy on 6/30/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

import Foundation

struct Student {
    var objectId:String
    var uniqueKey:String
    var firstName:String
    var lastName: String
    var mapString: String
    var mediaURL: String
    var latitude: Double
    var longitude: Double
    var updatedAt: String
    
    var name: String {
        return firstName + " " + lastName
    }
    
    var json: String {
        return "{\"uniqueKey\": \"\(uniqueKey)\", \"firstName\": \"\(firstName)\", \"lastName\": \"\(lastName)\",\"mapString\": \"\(mapString)\", \"mediaURL\": \"\(mediaURL)\",\"latitude\": \(latitude), \"longitude\": \(longitude)}"
    }
    
    //Initialize a Student Object with only three attributes because at the point of login no other attributes are known
    init(uniqueKey:String, firstName: String, lastName:String){ //Initialize the required fields
        self.uniqueKey = uniqueKey
        self.firstName = firstName
        self.lastName = lastName
        self.objectId = ""
        self.mapString = ""
        self.mediaURL = ""
        self.latitude = -0.0
        self.longitude = -0.0
        self.updatedAt = ""
    }
    
    init(dictionary: [String:AnyObject]) {
        objectId = dictionary["objectId"] as! String
        uniqueKey = dictionary["uniqueKey"] as! String
        firstName = dictionary["firstName"] as! String
        lastName = dictionary["lastName"] as! String
        mapString = dictionary["mapString"] as! String
        mediaURL = dictionary["mediaURL"] as! String
        latitude = dictionary["latitude"] as! Double
        longitude = dictionary["longitude"] as! Double
        updatedAt = dictionary["updatedAt"] as! String
    }
    
    mutating func getJSON() -> String {
        return "{\"uniqueKey\": \"\(uniqueKey)\", \"firstName\": \"\(firstName)\", \"lastName\": \"\(lastName)\",\"mapString\": \"\(mapString)\", \"mediaURL\": \"\(mediaURL)\",\"latitude\": \(latitude), \"longitude\": \(longitude)}"
    }
}