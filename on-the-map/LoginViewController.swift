//
//  ViewController.swift
//  on-the-map
//
//  Created by Mitchell Murphy on 7/4/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

import UIKit
import SystemConfiguration
import ReachabilitySwift

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var reachability: Reachability?
    
    var studentManager = StudentManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        
        setupReachabilty()
        
        
        // Do any additional setup after loading the view, typically from a nib.
        usernameTextField.becomeFirstResponder()
        //subscribeToKeyboardNotifications()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupReachabilty() {
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return
        }
        
        if let reachability = reachability {
            reachability.whenUnreachable = { reachability in
                // this is called on a background thread, but UI updates must
                // be on the main thread, like this:
                dispatch_async(dispatch_get_main_queue()) {
                    self.showAlert("Error", message: "No internet connection.")
                    self.loginButton.enabled = false
                }
            }
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification,object: reachability)
            do {
                try reachability.startNotifier()
            } catch {
                print("Unable to start notifier")
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        usernameTextField.text = ""
        passwordTextField.text = ""
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    func reachabilityChanged() {
        if let reachability = reachability {
            if reachability.isReachable() {
                performUIUpdatesOnMain({ 
                    self.loginButton.enabled = true
                })
            }
        }
    }
    
    
    @IBAction func login() {
        
        // validation step 1: make sure both fields are non-empty
        guard let username = usernameTextField.text where username != "" else {
            self.showAlert("oops...", message: "Make sure that both fields are entered and try again")
            return
        }
        
        guard let password = passwordTextField.text where password != "" else {
            self.showAlert("Oops", message: "Make sure that both fields are entered and try again")
            return
        }
        
        performUIUpdatesOnMain {
            self.activityIndicator.startAnimating()
        }
        // now try to login via Udacity
        studentManager.udacityClient.login(username, password: password) { (success, currentStudent, error) in
            
            if error != nil {
                self.showAlert("Error", message: "Unable to login. Check your credentials and try again.")
                performUIUpdatesOnMain({
                    self.activityIndicator.stopAnimating()
                })
                return
            }
            
            if success {
                
                if currentStudent != nil {
                    self.studentManager.currentStudent = currentStudent
                }
                
                performUIUpdatesOnMain({
                    self.activityIndicator.stopAnimating()
                    self.performSegueWithIdentifier("showHome", sender: nil)
                })
            }
        }
    }
    
    // MARK: - Keyboard methods
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        self.view.frame.origin.y = -getKeyboardHeight(notification)
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    func hideKeyboard() {
        view.endEditing(true)
    }
}

extension UIViewController {
    func showAlert(title: String?, message: String?) {
        dispatch_async(dispatch_get_main_queue()) {
            if title != nil && message != nil {
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                }
                alertController.addAction(OKAction)
                //self.presentViewController(alertController, animated: true, completion: nil)
                UIApplication.sharedApplication().delegate?.window!?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
}

