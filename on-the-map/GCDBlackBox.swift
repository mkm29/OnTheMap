//
//  GCDBlackBox.swift
//  FlickFinder
//
//  Created by Jarrod Parkes on 11/5/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}

//func showAlert(title: String?, message: String?) {
//    dispatch_async(dispatch_get_main_queue()) {
//        if title != nil && message != nil {
//            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
//            let appDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
//            print("attempting to present from rootVC")
//            appDelegate.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
//        }
//    }
//}