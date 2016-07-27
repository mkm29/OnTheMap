//
//  StudentMapViewController.swift
//  on-the-map
//
//  Created by Mitchell Murphy on 7/18/16.
//  Copyright © 2016 Mitchell Murphy. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import ReachabilitySwift

class StudentMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var studentManager = StudentManager.sharedInstance
    
    let locationManager = CLLocationManager()
    
    var reachability: Reachability?
    
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigatonBar()
        
        mapView.delegate = self
        subscribeToNotifications()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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
                if studentManager.students.count == 0 {
                    refresh()
                }
                addAnnotationsFromStudents()
            }
        }
    }
    
    private func setupNavigatonBar() {
        let dropPinButton = UIBarButtonItem(image: UIImage(named: "pin"), style: .Plain, target: self, action: #selector(dropPin))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(refresh))
        navigationItem.setRightBarButtonItems([refreshButton, dropPinButton], animated: true)
        
        let logoutButton = UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: #selector(logout))
        navigationItem.setLeftBarButtonItem(logoutButton, animated: true)
    }
    
    func refresh() {
        mapView.removeAnnotations(mapView.annotations)
        
        studentManager.students.removeAll()
        studentManager.parseClient.getStudentLocations({ (success, results, error) in
            guard let results = results else {
                self.showAlert("Error", message: "Results were not returned from Parse")
                return
            }
            
            if success {
                if let studentLocations = results["results"] as? [[String:AnyObject]] {
                    for student in studentLocations {
                        self.studentManager.students.append(Student(dictionary: student))
                    }
                    performUIUpdatesOnMain({
                        self.addAnnotationsFromStudents()
                    })
                }
            }
        })
    }
    
    // MARK: - Notifications
    private func subscribeToNotifications() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: #selector(refresh), name: Notifications.Refresh, object: nil)
        center.addObserver(self, selector: #selector(zoomToRegion), name: Notifications.Zoom, object: nil)
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
    
    func logout() {
        unsubscribeFromNotifications()
        studentManager.udacityClient.logout()
        studentManager.students.removeAll()
        studentManager.currentStudent = nil
        performUIUpdatesOnMain {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

// MARK: - MKMapViewDelegate methods

extension StudentMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:"pin")
        annotationView.annotation = annotation
        annotationView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        annotationView.canShowCallout = true
        annotationView.enabled = true
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let url = view.annotation?.subtitle {
            
            if let mediaURL = url {
                performUIUpdatesOnMain({
                    UIApplication.sharedApplication().openURL(NSURL(string: mediaURL)!)
                })
            }
        }
    }
}

extension StudentMapViewController: CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate {
    
    private func addAnnotationsFromStudents() {
        if studentManager.students.count > 0 {
            for student in studentManager.students {
                // only need these 2 attributes to add annotation to map
                if student.latitude != 0.0 && student.longitude != 0.0 {
                    let annotation = MKPointAnnotation()
                    let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(student.latitude), CLLocationDegrees(student.longitude))
                    annotation.coordinate = coordinate
                    annotation.title = student.name
                    annotation.subtitle = student.mediaURL
                    
                    
                    performUIUpdatesOnMain({
                        self.mapView.addAnnotation(annotation)
                    })
                }
            }
        }
    }
    
    
    func dropPin() {
        let studentDetailsVC = storyboard?.instantiateViewControllerWithIdentifier("studentDetailViewController") as! StudentDetailViewController
        _ = studentDetailsVC.view
        let navigationController = UINavigationController(rootViewController: studentDetailsVC)
        navigationController.navigationItem.title = "Map"
        presentViewController(navigationController, animated: true, completion: nil)
        
    }
    
    func showPopover() {
        let studentDetailViewController = storyboard?.instantiateViewControllerWithIdentifier("StudentDetailViewController") as! StudentDetailViewController
        studentDetailViewController.preferredContentSize = CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height / 3)
        
        let navigationController = UINavigationController(rootViewController: studentDetailViewController)
        navigationController.modalPresentationStyle = UIModalPresentationStyle.Popover
        
        let popOver = navigationController.popoverPresentationController
        popOver?.delegate = self
        //popOver?.sourceView = view
        popOver?.sourceRect = CGRectMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds),0,0)
        popOver?.barButtonItem = navigationItem.rightBarButtonItems![0]
        
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    func zoomToRegion() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //print("Received Zoom Notification")
        if let student = studentManager.currentStudent {
            //print("got student: \(student)")
            if student.latitude != -0.0 && student.longitude != -0.0 {
                //print("got lat and long")
                let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(student.latitude), CLLocationDegrees(student.longitude))
                let region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500)
                performUIUpdatesOnMain({ 
                    self.mapView.setRegion(region, animated: true)
                })
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
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
