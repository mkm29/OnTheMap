//
//  ParseClient.swift
//  udacity-on-the-map
//
//  Created by Mitchell Murphy on 6/7/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

import UIKit

class ParseClient: NSObject {
    
    static let sharedInstance = ParseClient()
    
    func getStudentLocations(completionHandler: (success: Bool, results: [String:AnyObject]?, error: NSError?) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: ParseClient.Constants.apiURL + "?limit=100&order=-updatedAt")!)
        request.addValue(ParseClient.Constants.applicationID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(ParseClient.Constants.restAPIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            func sendError(error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                let error = NSError(domain: error, code: 1, userInfo: userInfo)
                completionHandler(success: false, results: nil, error: error)
            }
            
            if error != nil {
                completionHandler(success: false, results: nil, error: error)
                return
            }
            guard let data = data else {
                sendError("No data was returned from Parse")
                return
            }
            // need to convert the JSON data now
            let parsedResults: AnyObject!
            
            do {
                parsedResults = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                sendError("Error parsing JSON")
                return
            }
            
            if let error = parsedResults["error"] as? String {
                sendError("Sorry not authorized to access Parse")
            }
            
            completionHandler(success: true, results: parsedResults as? [String:AnyObject], error: nil)
        }
        task.resume()
    }
    
    func poseToParse(student: Student, completionHandler: (success: Bool, objectId: String?, error: NSError?) -> Void ) {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://api.parse.com/1/classes/StudentLocation")!)
        request.HTTPMethod = "POST"
        request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = student.json.dataUsingEncoding(NSUTF8StringEncoding)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            func sendError(error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                let error = NSError(domain: error, code: 1, userInfo: userInfo)
                completionHandler(success: false, objectId: nil, error: error)
            }
            
            if let error = error {
                completionHandler(success: false, objectId: nil, error: error)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("invalid status code")
                return
            }
            
            guard let data = data else {
                sendError("no data returned")
                return
            }
            
            // now convert the data to JSON and try and grab the objectId
            var parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                sendError("Could not convert JSON data")
                return
            }
            
            guard let result = parsedResult as? [String:AnyObject] else {
                sendError("unable to cast JSON data")
                return
            }
            
            guard let objectId = result["objectId"] as? String else {
                sendError("Could not get objectId from JSON")
                return
            }
            
            completionHandler(success: true, objectId: objectId, error: nil)
            
        }
        task.resume()
    }
    
    func updateStudentLocation(student: Student, completionHandler: (success: Bool, results: AnyObject?, error: NSError?) -> Void) {
        var student = student
        let urlString = "https://api.parse.com/1/classes/StudentLocation/\(student.objectId)"
        let url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = student.getJSON().dataUsingEncoding(NSUTF8StringEncoding)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil { // Handle error…
                completionHandler(success: false, results: nil, error: error)
                return
            }
            print(NSString(data: data!, encoding: NSUTF8StringEncoding))
        }
        task.resume()
    }
    
    private func createError(error: String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : error]
        let error = NSError(domain: error, code: 1, userInfo: userInfo)
        return error
    }
}
