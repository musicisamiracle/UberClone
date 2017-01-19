//
//  RiderDetailViewController.swift
//  UberClone
//
//  Created by Dane Thomas on 1/13/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import MapKit
import Parse

// add viewWillAppear and have a check to see if the ride is still active, then it can segue back to maps or to the DriverTableVC if the ride is cancelled/accepted by someone else.

class RiderDetailViewController: UIViewController {

    @IBOutlet var map: MKMapView!
    @IBOutlet var acceptButton: UIButton!
    var rideRequest: PFObject?
    var riderCoordinate: CLLocationCoordinate2D?
    var timer = Timer()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @IBAction func acceptRider(_ sender: UIButton) {
        
        guard let riderLocation = riderCoordinate else {
            print("no location")
            return
        }
        
        guard let rideRequest = rideRequest else {
            print("no request")
            return
        }
        
        let rideQuery = PFQuery(className: "RequestedRides")
        rideQuery.includeKey("user")
        rideQuery.getObjectInBackground(withId: rideRequest.objectId!) { (object, error) in
            if error != nil {
                print(error.debugDescription)
                
                _ = self.navigationController?.popToRootViewController(animated: true)
                
                // cannot use self.createAlert() because the RiderDetailVC is not on the stack anymore
                let alert = UIAlertController(title: "Ride not found", message: "The ride may already have been accepted/cancelled", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                    action in
                    alert.dismiss(animated: false, completion: nil)
                }))
                self.present(alert, animated: false, completion: nil)
                
                return
            }
            
            if let ride = object {
                if (ride["accepted"] as! Bool) {
            
                    _ = self.navigationController?.popToRootViewController(animated: true)
                    
                    // cannot use self.createAlert() because the RiderDetailVC is not on the stack anymore
                    let alert = UIAlertController(title: "Ride not found", message: "The ride may already have been accepted/cancelled", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                        action in
                        alert.dismiss(animated: false, completion: nil)
                    }))
                    self.present(alert, animated: false, completion: nil)
                    
                    return
                }
                ride["accepted"] = true
                ride.saveInBackground(block: { (success, error) in
                    if success {
                        
                        let acceptedRide = PFObject(className: "AcceptedRides")
                        let accessControl = PFACL()
                        accessControl.getPublicReadAccess = true
                        accessControl.getPublicWriteAccess = true
                        acceptedRide.acl = accessControl
                        acceptedRide["driver"] = PFUser.current()
                        acceptedRide["rider"] = ride["user"] as! PFUser
                        acceptedRide["complete"] = false
                        PFGeoPoint.geoPointForCurrentLocation(inBackground: { (point, error) in
                            if error != nil {
                                print(error.debugDescription)
                            }
                            if let point = point {
                                acceptedRide["driverLocation"] = point
                                acceptedRide.saveInBackground()
                                
                                let placemark = MKPlacemark(coordinate: riderLocation, addressDictionary: nil)
                                let item = MKMapItem(placemark: placemark)
                                item.name = (ride["user"] as! PFUser)["username"] as? String
                                item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey: true])
                                
                                ride.deleteInBackground()
                                
                            }
                        })
                    }
                })
            }
            
        }
        
    }
    
    func updateRide() {
        let query = PFQuery(className: "AcceptedRides")
        query.whereKey("driver", equalTo: PFUser.current())
        query.whereKey("complete", equalTo: false)
        query.getFirstObjectInBackground { [unowned self] (object, error) in
            if error != nil {
                print(error.debugDescription)
            }
            
            if let ride = object {
                PFGeoPoint.geoPointForCurrentLocation(inBackground: { (point, error) in
                    if error != nil {
                        print(error.debugDescription)
                    }
                    if let point = point {
                        ride["driverLocation"] = point
                        ride.saveInBackground()
                    }
                })
            }
            else {
                self.timer.invalidate()
            }
        }
    }
    
    func updateLocationOnTimer() {
        print("in background")
        timer = Timer(timeInterval: 5, target: self, selector: #selector(updateRide), userInfo: nil, repeats: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // having an issue with snapshot of view when entering background
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocationOnTimer), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        map.showsUserLocation = true
        map.isZoomEnabled = true
        
        guard let riderName = (rideRequest?["user"] as? PFUser)?["username"] as? String else {
            print("could not get username")
            return
        }
        guard let riderGeoPoint = rideRequest?["location"] as? PFGeoPoint else {
            print("could not get location")
            return
        }
        
        let annotation = MKPointAnnotation()
        annotation.title = riderName
        riderCoordinate = CLLocationCoordinate2D(latitude: riderGeoPoint.latitude, longitude: riderGeoPoint.longitude)
        annotation.coordinate = riderCoordinate!
        map.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(center: riderCoordinate!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map.setRegion(region, animated: true)

        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
