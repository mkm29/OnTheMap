//
//  HomeTabBarController.swift
//  on-the-map
//
//  Created by Mitchell Murphy on 7/7/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

import UIKit

class HomeTabBarController: UITabBarController {
    
    var currentStudent: Student?
    
    var shouldGetStudent: Bool = false
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldGetStudent {
            getStudentDataForCurrentStudent()
            print(currentStudent)
        }
    }
    
    private func getStudentDataForCurrentStudent() {
        if let key = UdacityClient.sharedInstance().userId {
            ParseClient.sharedInstance().getUserData(key, completionHandler: { (success, results, error) in
                if success {
                    print(results)
                    
                    guard let results = results else {
                        return
                    }
                    
                    guard let firstName = results["first_name"] as? String else {
                        return
                    }
                    
                    guard let lastName = results["last_name"] as? String else {
                        return
                    }
                    
                    self.currentStudent = Student(uniqueKey: UdacityClient.sharedInstance().userId!, firstName: firstName, lastName: lastName)
                    
                    self.shouldGetStudent = false
                }
            })
        }
        
    }
}
