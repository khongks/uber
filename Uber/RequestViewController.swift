//
//  RequestViewController.swift
//  Uber
//
//  Created by khongks on 28/02/2016.
//  Copyright © 2016 spocktech. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RequestViewController: UIViewController, CLLocationManagerDelegate {
    
    var request: RiderRequest!

    @IBOutlet weak var mapView: MKMapView!
    
    func goToMap(latitude: CLLocationDegrees, longitude: CLLocationDegrees, venueName: String) {
        
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(MKCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = venueName
        mapItem.openInMapsWithLaunchOptions(options)
    }
    
    @IBAction func pickUp(sender: AnyObject) {
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: request.username)
        query.findObjectsInBackgroundWithBlock { (requests, error) -> Void in
            if error == nil {
                if let requests = requests {
                    for request in requests {
                        let query = PFQuery(className: "RiderRequest")
                        query.getObjectInBackgroundWithId(request.objectId!, block: { (request, error) -> Void in
                            if error == nil {
                                request!["driverResponded"] = PFUser.currentUser()?.username
                                do { try request?.save() } catch { print ("save error") }
                                
                                let requestCLLocation = CLLocation(latitude: self.request.location.latitude, longitude: self.request.location.longitude)
                                
                                CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: { (placemarks, error) -> Void in
                                    if error != nil {
                                        print (error)
                                    } else {
                                        if placemarks?.count > 0 {
                                            let pm = placemarks![0] as CLPlacemark
                                            let mkPm = MKPlacemark(placemark: pm)
                                            let mapItem = MKMapItem(placemark: mkPm)
                                            mapItem.name = self.request.username
                                            let launchOptions = [
                                                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                                            ]
                                            mapItem.openInMapsWithLaunchOptions(launchOptions)
                                        }
                                    }
                                })
                                //self.goToMap(self.request.location.latitude, longitude: self.request.location.longitude, venueName: self.request.username)
                            } else {
                                print ("get object error")
                            }
                        })
                    }
                }
            } else {
                print ("error findObjectsInBackgroundWithBlock")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print ("username: \(request.username)")
        print ("location: \(request.location)")
        print ("distance: \(request.distanceFromLocation)")
        
        let location = request.location
        
        let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
        
        // Remove old Pins
        mapView.removeAnnotations(mapView.annotations)
        
        // Add new Pin
        let pinLocation = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = pinLocation
        objectAnnotation.title = request.username
        self.mapView.addAnnotation(objectAnnotation)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
