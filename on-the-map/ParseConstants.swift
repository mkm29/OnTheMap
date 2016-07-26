//
//  ParseConstants.swift
//  udacity-on-the-map
//
//  Created by Mitchell Murphy on 6/7/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

extension ParseClient {
    struct Constants {
        static let applicationID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
        static let restAPIKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
        static let apiURL = "https://api.parse.com/1/classes/StudentLocation/"
    }
    
    struct JSONResponseKeys {
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let mapString = "mapString"
        static let mediaURL = "mediaURL"
        static let objectId = "objectId"
        static let uniqueKey = "uniqueKey"
    }
}
