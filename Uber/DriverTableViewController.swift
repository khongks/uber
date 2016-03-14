//
//  DriverTableViewController.swift
//  Uber
//
//  Created by khongks on 28/02/2016.
//  Copyright © 2016 spocktech. All rights reserved.
//

import UIKit
import Parse
import MapKit

class DriverTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    var riderRequests = [String:RiderRequest]()
    var locationManager = CLLocationManager()
    var myLocation: PFGeoPoint!
    
//    struct RiderRequest {
//        var username : String!
//        var location : CLLocationCoordinate2D!
//        var distanceFromLocation: CLLocationDistance!
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //findRiderRequests()
        startAcquireGeolocation()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func startAcquireGeolocation() {
        // Get location of Device
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Import to enable capabilities - location updates in backgroun
        locationManager.requestAlwaysAuthorization()
        //locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func findNearestRiderRequests(myLatitude: Double, myLongitude: Double) {
        let query = PFQuery(className: "RiderRequest")
        let driverLocation = PFGeoPoint(latitude:myLatitude, longitude: myLongitude)
        query.whereKey("location", nearGeoPoint: driverLocation)
        query.limit = 10
        query.findObjectsInBackgroundWithBlock { (requests, error) -> Void in
            if error == nil {
                //print ("no error findObjectsInBackgroundWithBlock \(requests?.count)")
                if let requests = requests {
                    self.riderRequests.removeAll()
                    for request in requests {
                        if request["driverResponded"] == nil {
                            let riderRequest = RiderRequest()
                            riderRequest.username = request["username"]! as! String
                            let location = request["location"]! as! PFGeoPoint
                            let reqLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                            riderRequest.location = reqLocation
                            let reqCLLocation = CLLocation(latitude: reqLocation.latitude, longitude: reqLocation.longitude)
                            let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                            riderRequest.distanceFromLocation = driverCLLocation.distanceFromLocation(reqCLLocation)
                            self.riderRequests[request["username"]! as! String] = riderRequest
                            //print ("number of riderRequests = \(self.riderRequests.count)")
                        }
                    }
                    self.tableView.reloadData()
                }
            } else {
                print ("error findObjectsInBackgroundWithBlock")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        //print ("number of riderRequests = \(self.riderRequests.count)")
        return riderRequests.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RequestCell", forIndexPath: indexPath)
        let index = riderRequests.startIndex.advancedBy(indexPath.row)
        
        let distanceInDouble = Double(riderRequests.values[index].distanceFromLocation/1000)
        let roundedDistance = Double(round(distanceInDouble*10)/10)
        
        cell.textLabel!.text = "\(riderRequests.keys[index]) - \(roundedDistance) kms away"
        return cell
    }
    
    func updateDriverLocation(location: PFGeoPoint) {
        PFUser.currentUser()!["location"] = location
        PFUser.currentUser()?.saveInBackground()
    }

    // Called when locations are updated
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
        let location = locations.last! as CLLocation
        let myLocation = PFGeoPoint(location: location)
        print ("lat=\(location.coordinate.latitude), long=\(location.coordinate.longitude)")
        
        if PFUser.currentUser() != nil {
            findNearestRiderRequests(location.coordinate.latitude, myLongitude: location.coordinate.longitude)
            updateDriverLocation(myLocation)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "logoutDriver" {
            navigationController?.setNavigationBarHidden(true, animated: true)
            locationManager.stopUpdatingLocation()
            print ("logout")
            PFUser.logOut()
        } else if segue.identifier == "showViewRequest" {
            if let destination = segue.destinationViewController as? RequestViewController {
                let index = riderRequests.startIndex.advancedBy(tableView.indexPathForSelectedRow!.row)
                destination.request = riderRequests.values[index]
            }
        }
    }

}
