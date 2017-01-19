//
//  DriverTableViewController.swift
//  UberClone
//
//  Created by Dane Thomas on 1/12/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse

// Should have some way of knowing a ride is in progress.

class DriverTableViewController: UITableViewController {

    var rideRequests: [PFObject] = []
    var driverLocation: PFGeoPoint?
    var selectedRequest: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
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
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logOut" {
            PFUser.logOut()
        }
        
        if segue.identifier == "toRiderDetail" {
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
