//
//  UdacityClient.swift
//  udacity-on-the-map
//
//  Created by Mitchell Murphy on 6/6/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

import Foundation

class UdacityClient: NSObject {
    
    static let sharedInstance = UdacityClient()
    
    var session = NSURLSession.sharedSession()
    
    var sessionId: String? = nil
    
    
    // this login function only creates a session with the given credentials
    // you must call the getUserData function for further Student initialization
    
    func login(username: String, password: String, completionHandler: (success: Bool, currentStudent: Student?, error: NSError?) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://www.udacity.com/api/session")!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func sendError(error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                let error = NSError(domain: error, code: 1, userInfo: userInfo)
                completionHandler(success: false, currentStudent: nil, error: error)
            }
            
            if let error = error {
                sendError(error.localizedDescription)
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
            
            let range = NSMakeRange(5, data.length)
            let dataWithOutFirst5 = data.subdataWithRange(range)
            
            // convert the data for parsing
            var parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(dataWithOutFirst5, options: .AllowFragments)
            } catch {
                sendError("Could not convert JSON data")
                return
            }
            
            guard let result = parsedResult as? [String:AnyObject] else {
                sendError("unable to cast JSON data")
                return
            }
            
            guard let session = result["session"] as? [String:AnyObject] else {
                sendError("could not get session dictionary from JSON")
                return
            }
            guard let sessionId = session["id"] as? String else {
                sendError("id key not found in session JSON")
                return
            }
            self.sessionId = sessionId
            
            guard let account = result["account"] as? [String:AnyObject] else {
                sendError("Account info not found")
                return
            }
            
            guard let uniqueKey = account["key"] as? String else {
                sendError("Unable to get account key")
                return
            }
            
            // now get the user data from Udacity
            self.getUserData(uniqueKey, completionHandler: { (success, userData, error) in
                if success {
                    if let userData = userData {
                        
                        if let firstName = userData["first_name"] as? String, lastName = userData["last_name"] as? String {
                            let currentStudent = Student(uniqueKey: uniqueKey, firstName: firstName, lastName: lastName)
                            completionHandler(success: true, currentStudent: currentStudent, error: nil)
                        }
                    }
                }
                
            })
        }
        
        task.resume()
    }
    
    func getUserData(key: String, completionHandler: (success: Bool, results: [String:AnyObject]?, error: NSError?) -> Void) {
        let urlString: String = "https://www.udacity.com/api/users/" + key
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            func sendError(error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                let error = NSError(domain: error, code: 1, userInfo: userInfo)
                completionHandler(success: false, results: nil, error: error)
            }
            
            if error != nil { // Handle error...
                completionHandler(success: false, results: nil, error: error)
                return
            }
            guard let data = data else {
                sendError("no user data returned")
                return
            }
            let range = NSMakeRange(5, data.length)
            let dataWithOutFirst5 = data.subdataWithRange(range)
            
            var parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(dataWithOutFirst5, options: .AllowFragments)
            } catch {
                sendError("Could not convert JSON data")
                return
            }
            
            guard let result = parsedResult["user"] as? [String:AnyObject] else {
                sendError("unable to cast JSON data")
                return
            }
            completionHandler(success: true, results: result, error: nil)
        }
        task.resume()
    }
    
    func logout() {
        sessionId = nil
        //currentStudent = nil
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://www.udacity.com/api/session")!)
        request.HTTPMethod = "DELETE"
        var xsrfCookie: NSHTTPCookie? = nil
        let sharedCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil { // Handle error…
                return
            }
        }
        task.resume()
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }
}
