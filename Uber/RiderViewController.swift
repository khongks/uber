//
//  RiderViewController.swift
//  Uber
//
//  Created by khongks on 26/02/2016.
//  Copyright © 2016 spocktech. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var locationManager = CLLocationManager()
    var myLocation: PFGeoPoint!
    
    var requestType = "CallUber"
    var isResponded: Bool = false
    
    @IBAction func sendRequestToUber(sender: AnyObject) {
        
        if requestType == "CallUber" {
            requestType = "CancelUber"
            callUber()
        } else if requestType == "CancelUber" {
            requestType = "CallUber"
            cancelUber()
        }
    }
    
    func isRequestPending() {
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)
        query.findObjectsInBackgroundWithBlock {
            (objects:[PFObject]?, error: NSError?) -> Void in
            if let error = error {
                let errorString = error.userInfo["error"] as? String
                self.displayAlert("Error", message: errorString!)
            } else {
                if let objects = objects {
                    for object in objects {
                        if let _ = object["driverResponded"] {
                            self.isResponded = true
                        } else {
                            self.isResponded = false
                        }
                        self.requestType = "CancelUber"
                        self.requestButton.setTitle("Cancel", forState: .Normal)
                    }
                    
                }
            }
        }
        
    }
    
    func callUber() {
        
        if let myLocation = myLocation {
            let request = PFObject(className: "RiderRequest")
            request["username"] = PFUser.currentUser()?.username
            request["location"] = myLocation
            request.saveInBackgroundWithBlock { (isOK, error) -> Void in
                if let error = error {
                    let errorString = error.userInfo["error"] as? String
                    self.displayAlert("Error", message: errorString!)
                } else if isOK {
                    //self.displayAlert("Info", message: "Call Uber Request OK")
                    self.requestButton.setTitle("Cancel", forState: .Normal)
                }
            }
        } else {
            self.displayAlert("Error", message: "Cannot get your location")
        }
    }
    
    func cancelUber() {
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)
        query.findObjectsInBackgroundWithBlock {
            (objects:[PFObject]?, error: NSError?) -> Void in
            if let error = error {
                let errorString = error.userInfo["error"] as? String
                self.displayAlert("Error", message: errorString!)
            } else {
                if let objects = objects {
                    for object in objects {
                        object.deleteInBackground()
                        self.isResponded = false
                    }
                    
                }
                self.requestButton.setTitle("Call", forState: .Normal)
            }
        }
    }
    
    
    func startAcquireGeolocation() {
        print ("startAcquireGeolocation")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        // Add these 2 in Info.plist
        // 1: NSLocationWhenInUseUsageDescription
        // 2: NSLocationAlwaysUsageDescription
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isRequestPending()
        // Get location of Device
        startAcquireGeolocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "logoutRider" {
            locationManager.stopUpdatingLocation()
            PFUser.logOut()
        }
    }
    
    // Called when locations are updated
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        myLocation = PFGeoPoint(location: location)
        
        //print ("lat=\(location.coordinate.latitude), long=\(location.coordinate.longitude)")
        
        if isResponded == false {
            prepareCreateAnnotationOnMap(location.coordinate.latitude, longitude: location.coordinate.longitude, latDelta: 0.01, longDelta: 0.01)
            createAnnotationOnMap("Me", latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        
        // check if driver has responded
        markDriverLocation(location)
    }
    
    func prepareCreateAnnotationOnMap(latitude: CLLocationDegrees, longitude: CLLocationDegrees, latDelta: Double, longDelta: Double) {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta))
        mapView.setRegion(region, animated: true)
        // Remove old Pins
        mapView.removeAnnotations(mapView.annotations)
    }

    func createAnnotationOnMap(title: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        // Add new Pin
        let pinLocation = CLLocationCoordinate2DMake(latitude, longitude)
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = pinLocation
        objectAnnotation.title = title
        mapView.addAnnotation(objectAnnotation)
    }

    func markDriverLocation(riderLocation: CLLocation) {

        // *** find rider request by username
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)
        query.findObjectsInBackgroundWithBlock {
            (objects:[PFObject]?, error: NSError?) -> Void in
            if let error = error {
                let errorString = error.userInfo["error"] as? String
                self.displayAlert("Error", message: errorString!)
            } else {
                if let objects = objects {
                    for object in objects {
                        if let driverResponded = object["driverResponded"] {
                            
                            self.isResponded = true
                            
                            let driverName = driverResponded as! String
                            
                            // *** find the driver
                            let query = PFUser.query()
                            query?.whereKey("username", equalTo: driverName)
                            query?.findObjectsInBackgroundWithBlock({ (objects , error) -> Void in
                                if let error = error {
                                    let errorString = error.userInfo["error"] as? String
                                    self.displayAlert("Error", message: errorString!)
                                } else {
                                    if let objects = objects {
                                        for object in objects {
                                            if let driverLocation = object["location"] as? PFGeoPoint {
                                                
                                                // *** get the driver location
                                                //print ("driverlocation: \(driverLocation)")
                                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                
                                                // *** find the distance between driver and rider
                                                let distanceInMeters = riderLocation.distanceFromLocation(driverCLLocation)
                                                let distanceInKMs = distanceInMeters/1000
                                                let roundedDistanceInKM = Double(round(distanceInKMs*10)/10)
                                                print (roundedDistanceInKM)
                                                self.distanceLabel.text = "Dist: \(roundedDistanceInKM)km"
                                                
                                                // *** Create annonation of driver and rider
                                                
                                                if self.isResponded == true {
                                                    
                                                    print ("isResponded")
                                                
                                                    let latDelta = abs(driverLocation.latitude - riderLocation.coordinate.latitude) * 2 + 0.005
                                                    let longDelta = abs(driverLocation.longitude - riderLocation.coordinate.longitude) * 2 + 0.005
                                                
                                                    self.prepareCreateAnnotationOnMap(riderLocation.coordinate.latitude, longitude: riderLocation.coordinate.longitude, latDelta: latDelta, longDelta: longDelta)
                                                
                                                    self.createAnnotationOnMap("Me", latitude: riderLocation.coordinate.latitude, longitude: riderLocation.coordinate.longitude)
                                                
                                                    self.createAnnotationOnMap(driverName, latitude: driverCLLocation.coordinate.latitude, longitude: driverCLLocation.coordinate.longitude)
                                                }
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
        
        // If responded, set button to Responded
        
        // Get location of driver
        
        // Get the distance
        
        // Create annotation on map
        
        // Scale the map
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

}
