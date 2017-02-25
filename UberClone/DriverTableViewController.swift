//
//  DriverTableViewController.swift
//  UberClone
//
//  Created by Dane Thomas on 1/12/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit


class DriverTableViewController: UITableViewController {

    //MARK: Properties
    var rideRequests: [PFObject] = []
    var driverLocation: PFGeoPoint?
    var selectedRequest: PFObject!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check for a ride in progress
        let inProgressQuery = PFQuery(className: "AcceptedRides")
        inProgressQuery.whereKey("driver", equalTo: PFUser.current()!)
        inProgressQuery.whereKey("complete", equalTo: false)
        inProgressQuery.getFirstObjectInBackground { (object, error) in
            if error != nil {
                print(error.debugDescription)
                
                return
            }
            
            if object != nil {
                
                guard let riderLatitude = UserDefaults.standard.object(forKey: "riderLatitude") as? Double else {
                    print("no rider latitude saved")
                    return
                }
                guard let riderLongitude = UserDefaults.standard.object(forKey: "riderLongitude") as? Double else {
                    print("no rider longitude saved")
                    return
                }
                
                let riderLocation = CLLocationCoordinate2D(latitude: riderLatitude, longitude: riderLongitude)
                let placemark = MKPlacemark(coordinate: riderLocation, addressDictionary: nil)
                let item = MKMapItem(placemark: placemark)
                item.name = UserDefaults.standard.string(forKey: "riderName")
                item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey: true])
                
            }
            else {
               UserDefaults.standard.removeObject(forKey: "riderLatitude")
               UserDefaults.standard.removeObject(forKey: "riderLongitude")
                UserDefaults.standard.removeObject(forKey: "riderName")
            }
        }
        
        // If no rides in progress, update table with requested rides
        PFGeoPoint.geoPointForCurrentLocation { [unowned self] (point, error) in
            if error != nil {
                print(error.debugDescription)
            }
            
            if let point = point {
                self.driverLocation = point
                
                let query = PFQuery(className: "RequestedRides")
                query.whereKey("accepted", equalTo: false)
                query.whereKey("location", nearGeoPoint: point)
                query.includeKey("user")
                query.findObjectsInBackground { [unowned self] (objects, error) in
                    if error != nil {
                        print(error.debugDescription)
                    }
                    if let requests = objects {
                        self.rideRequests = requests
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  rideRequests.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "requestedRiders", for: indexPath) as! RiderTableViewCell
        let rider = rideRequests[indexPath.row]
        
        cell.nameLabel.text = (rider["user"] as! PFUser)["username"] as? String
        
        if var distanceToRider = driverLocation?.distanceInMiles(to: rider["location"] as? PFGeoPoint) {
            distanceToRider = round(distanceToRider, numOfPlaces: 2)
            cell.distanceLabel.text = "\(distanceToRider) mi. away"
        }
        else {
            cell.distanceLabel.text = "Unable to determine distance"
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRequest = rideRequests[indexPath.row]
        performSegue(withIdentifier: "toRiderDetail", sender: self)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logOut" {
            PFUser.logOut()
        }
        
        if segue.identifier == "toRiderDetail" {
            let riderLatitude = (selectedRequest["location"] as! PFGeoPoint).latitude
            let riderLongitude = (selectedRequest["location"] as! PFGeoPoint).longitude
            let riderName = (selectedRequest["user"] as! PFUser).username
            
            
            UserDefaults.standard.set(riderLatitude, forKey: "riderLatitude")
            UserDefaults.standard.set(riderLongitude, forKey: "riderLongitude")
            UserDefaults.standard.set(riderName, forKey: "riderName")
            if let RiderDetailController = segue.destination as? RiderDetailViewController {
                RiderDetailController.rideRequest = selectedRequest
            }
        }
    }
    
    func round(_ double: Double, numOfPlaces: Int) -> Double {
        let divisor = pow(10.0, Double(numOfPlaces))
        
        return ((double * divisor).rounded()) / divisor
    }
    

}
