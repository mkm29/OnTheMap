//
//  StudentDetailViewController.swift
//  on-the-map
//
//  Created by Mitchell Murphy on 7/17/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

import UIKit
import CoreLocation
import ReachabilitySwift
import MapKit

class StudentDetailViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - variables/properties and outlets
    var studentManager = StudentManager.sharedInstance
    let locationManager = CLLocationManager()
    var reachability: Reachability?
    
    @IBOutlet weak var mapString: UITextField!
    @IBOutlet weak var mediaURL: UITextField!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var mapView: MKMapView!
    
     // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(tapGesture)
        
        mediaURL.hidden = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //student = studentManager.currentStudent
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(save))
        navigationItem.setRightBarButtonItem(saveButton, animated: true)
        // now set up the navBar
        let backButton = UIBarButtonItem(title: "Back", style: .Done, target: self, action: #selector(back))
        navigationItem.setLeftBarButtonItem(backButton, animated: true)
        
        // we have ensured that the student var is not nil
        if studentManager.currentStudent != nil {
            navigationItem.title = studentManager.currentStudent?.name
        } else {
            back()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        subscribeToKeyboardNotifications()
        
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
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
    }
    
    func back() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func save() -> Void {
        // update the student in the appDelegate and dismiss VC
        // student will never be nil (check in viewDidAppear)
        
        // we know that the student variable is never going to be nil here
        
        var errorString = ""
        
        if mediaURL.text! == "" {
            errorString.appendContentsOf("The media URL field cannot be empty. ")
        }
        if mapString.text! == "" {
            errorString.appendContentsOf("The map string field cannot be empty. ")
        }
        
        if errorString != "" {
            showAlert("Error", message: errorString)
            return
        }
        
        let studentInfo = [
            "mapString" : mapString.text!,
            "mediaURL" : mediaURL.text!
        ]
        studentManager.setStudentAttributes(studentInfo)
        print(studentManager.currentStudent)
        
        // now need to post the student to Parse and dismiss VC
        studentManager.parseClient.poseToParse(studentManager.currentStudent!) { (success, objectId, error) in
            if error != nil {
                self.showAlert("Error", message: "There was an issue posting the current student to Parse. Try again later")
            }
            if success {
                print(objectId)
                if let objectId = objectId {
                    self.studentManager.setObjectId(objectId)
                }
            } else {
                self.showAlert("Error", message: "There was an issue posting the current student to Parse. Try again later")
            }
            self.dismissViewControllerAnimated(true, completion: { 
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.Refresh, object: nil)
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.Zoom, object: nil)
            })
        }
    }
    
    @IBAction func findLocation() {
        if mapString.text != "" {
            activityIndicator.startAnimating()
            
            let geocoder = CLGeocoder()
            
            geocoder.geocodeAddressString(mapString.text!, completionHandler: { (placemarks, error) in
                self.activityIndicator.stopAnimating()
                if error != nil {
                    self.showAlert("Error", message: "Sorry the geocoding process failed. Please re-enter map string and try aggain")
                    return
                }
                
                if let placemarks = placemarks {
                    if let placemark = placemarks.first {
                        // update the current student
                        self.studentManager.setStudentLocation(placemark)
                        self.mediaURL.hidden = false
                        self.mediaURL.becomeFirstResponder()
                        // now need to zoom to the area
                        self.zoomToPlacemark(placemark)
                    } else {
                        self.showAlert("Error", message: "Sorry there were no placemarks matching your searcgh")
                        return
                    }
                } else {
                    self.showAlert("Error", message: "Sorry there were no placemarks matching your searcgh")
                    return
                }
            })
        } else {
           showAlert("Oops", message: "Make sure that the map string field is complete and try again")
        }
        
        
    }
    
    func zoomToPlacemark(placemark: CLPlacemark) {
        if let lat = placemark.location?.coordinate.latitude, long = placemark.location?.coordinate.longitude {
            let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(lat), CLLocationDegrees(long))
            let region = MKCoordinateRegionMakeWithDistance(coordinate, 2000, 2000)
            
            let mkPlacemark = MKPlacemark(placemark: placemark)
            
            performUIUpdatesOnMain({
                self.mapView.setRegion(region, animated: true)
                self.mapView.addAnnotation(mkPlacemark)
            })
        }
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
    
    // MARK: - Keyboard methods
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
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
