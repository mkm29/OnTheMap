//
//  StudentTableViewController.swift
//  on-the-map
//
//  Created by Mitchell Murphy on 7/7/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

import UIKit
import ReachabilitySwift

class StudentTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    var studentManager = StudentManager.sharedInstance
    
    var reachability: Reachability?
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        setupNavigationController()
        
        subscribeToNotifications()
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            showAlert("Error", message: "Unable to create Reachability")
            return
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification,object: reachability)
        do{
            try reachability?.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
        
        if let reachability = reachability {
            if reachability.isReachable() {
                refresh()
            }
        }
    }
    
    
    // MARK: - Notifications
    
    private func subscribeToNotifications() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: #selector(refresh), name: Notifications.Refresh, object: nil)
    }
    
    func reachabilityChanged(note: NSNotification) {
        
        let reachability = note.object as! Reachability
        
        if !reachability.isReachable() {
            showAlert("Error", message: "Network not reachable. Please connect and try again.")
        }
    }
    
    func unsubscribeFromNotifications() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self, name: Notifications.Refresh, object: nil)
        center.removeObserver(self, name: ReachabilityChangedNotification, object: reachability)
    }
    
    
    private func setupNavigationController() {
        navigationItem.title = "Students"
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(add))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(refresh))
        navigationItem.setRightBarButtonItems([addButton, refreshButton], animated: true)
        
        let logoutButton = UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: #selector(logout))
        navigationItem.setLeftBarButtonItem(logoutButton, animated: true)
    }
    
    func add() {
        // grab the current student from the appDelegate
        let studentDetailsVC = storyboard?.instantiateViewControllerWithIdentifier("StudentDetailViewController") as! StudentDetailViewController
        let navigationController = UINavigationController(rootViewController: studentDetailsVC)
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
    
    func refresh() {
        studentManager.students.removeAll()
        studentManager.parseClient.getStudentLocations({ (success, results, error) in
            
            if let error = error {
                self.showAlert("Error", message: error.localizedDescription)
            }
            
            if success {
                if let results = results {
                    if let studentLocations = results["results"] as? [[String:AnyObject]] {
                        for student in studentLocations {
                            self.studentManager.students.append(Student(dictionary: student))
                        }
                        performUIUpdatesOnMain({
                            self.tableView.reloadData()
                        })
                    }
                }
                
            }
        })
    }
    
    func logout() {
        if let reachability = reachability {
            reachability.stopNotifier()
        }
        
        unsubscribeFromNotifications()
        performUIUpdatesOnMain {
            self.dismissViewControllerAnimated(true, completion: { 
                self.studentManager.udacityClient.logout()
            })
        }
    }
    
    // MARK: - UITableViewController delegate methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentManager.students.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("StudentCell")
        
        
        // now grab the student
        let student = studentManager.students[indexPath.row]
        cell?.textLabel?.text = student.name
        cell?.detailTextLabel?.text = student.mediaURL
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // if student cell has valid URL link, go to it
        let student = studentManager.students[indexPath.row]
        if student.mediaURL != "" {
            if verifyURL(student.mediaURL) {
                UIApplication.sharedApplication().openURL(NSURL(string: student.mediaURL)!)
            }
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let student = studentManager.students[indexPath.row]
        
        
    }
    
    private func showStudentDetails() {
        let studentDetailsVC = storyboard?.instantiateViewControllerWithIdentifier("StudentDetailViewController") as! StudentDetailViewController
        let navigationController = UINavigationController(rootViewController: studentDetailsVC)
        presentViewController(navigationController, animated: true, completion: nil)  
    }
    
    private func verifyURL(urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url  = NSURL(string: urlString) {
                return UIApplication.sharedApplication().canOpenURL(url)
            }
        }
        return false
    }
    
    override func showAlert(title: String?, message: String?) {
        dispatch_async(dispatch_get_main_queue()) {
            if title != nil && message != nil {
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                
                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                }
                alertController.addAction(OKAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
}
