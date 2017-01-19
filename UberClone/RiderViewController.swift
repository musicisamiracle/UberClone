//
//  RiderViewController.swift
//  UberClone
//
//  Created by Dane Thomas on 1/12/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RiderViewController: UIViewController {

    @IBOutlet var rideCompletedButton: UIButton!
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var callUberButton: UIButton!
    var currentUser: PFUser!
    var callingAnUber = true
    var acceptedRideId: String?
    var currentLocation: PFGeoPoint?
    var driver = MKPointAnnotation()

    enum RequestUpdateType: Int {
        case refresh, cancel
    }
    
    enum RiderViewState: Int {
        case noRequests, awaitingAccept, accepted
    }

    @IBAction func callUber(_ sender: UIButton) {
        
        if callingAnUber {
            let newLocation = PFObject(className: "RequestedRides")
            newLocation["user"] = currentUser
            newLocation["accepted"] = false
            let access = PFACL()
            access.getPublicWriteAccess = true
            access.getPublicReadAccess = true
            newLocation.acl = access
            
            PFGeoPoint.geoPointForCurrentLocation(inBackground: { [unowned self] (point, error) in
                if error != nil {
                    print(error.debugDescription)
                }
                if let point = point {
                    newLocation["location"] = point
                    newLocation.saveInBackground()
                    sender.setTitle("Cancel Uber", for: [])
                    self.callingAnUber = false
                    self.rideCompletedButton.isHidden = true
                }
            })
        }
        else {
            updateOpenRequests(type: .cancel)
        }
        
    }
    
    @IBAction func completeRide(_ sender: UIButton) {
        guard let objectId = acceptedRideId else {
            print("no object id")
            return
        }
        
        let query = PFQuery(className: "AcceptedRides")
        query.getObjectInBackground(withId: objectId) { [unowned self] (object, error) in
            if error != nil {
                print(error.debugDescription)
            }
            
            if let ride = object {
                ride["complete"] = true
                ride.saveInBackground()
                self.map.removeAnnotation(self.driver)
                self.updateOpenRequests(type: .refresh)
            }
        }
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        currentUser = PFUser.current()
        
        map.showsUserLocation = true
        map.isZoomEnabled = true
        map.userTrackingMode = .follow
        
        PFGeoPoint.geoPointForCurrentLocation { [unowned self] (point, error) in
            if error != nil {
                print(error.debugDescription)
            }
            
            if let point = point {
                self.currentLocation = point
            }
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logOut" {
            PFUser.logOut()
        }
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        updateOpenRequests(type: .refresh)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func updateOpenRequests(type: RequestUpdateType) {
        
        let query = PFQuery(className: "RequestedRides")
        query.whereKey("user", equalTo: currentUser)
        query.whereKey("accepted", equalTo: false)
        query.addAscendingOrder("createdAt")
        query.getFirstObjectInBackground(block: { [unowned self] (object, error) in
            if error != nil {
                print(error.debugDescription)
            }
            
            if let request = object {
                
                switch type {
                    
                case .refresh:
                    self.setStateforView(.awaitingAccept)
                    
                case .cancel:
                    request.deleteInBackground()
                    self.setStateforView(.noRequests)
                }
            }
            else {
                self.checkAcceptedRides()
            }
        })
        
    }
    func checkAcceptedRides() {
        let acceptedQuery = PFQuery(className: "AcceptedRides")
        acceptedQuery.whereKey("rider", equalTo: self.currentUser)
        acceptedQuery.whereKey("complete", equalTo: false)
        acceptedQuery.getFirstObjectInBackground(block: { [unowned self] (object, error) in
            
            if error != nil {
                print(error.debugDescription)
            }
            
            if let ride = object {
                self.acceptedRideId = ride.objectId
                self.setStateforView(.accepted)
                
                self.driver = MKPointAnnotation()
                let driverGeoPoint = ride["driverLocation"] as! PFGeoPoint
                self.driver.coordinate = CLLocationCoordinate2D(latitude: driverGeoPoint.latitude, longitude: driverGeoPoint.longitude)
                self.driver.title = "Your driver"
                self.map.addAnnotation(self.driver)
                
                if var distanceToDriver = self.currentLocation?.distanceInMiles(to: ride["driverLocation"] as? PFGeoPoint) {
                    distanceToDriver = self.round(distanceToDriver, numOfPlaces: 2)
                    self.createAlert(title: "Your driver is near!", message: "Your driver is \(distanceToDriver) mi. away")
                }
                
            }
            else {
                self.setStateforView(.noRequests)
            }
        })
    }
    
    func setStateforView(_ state: RiderViewState) {
        switch state {
        case .noRequests:
            callingAnUber = true
            callUberButton.isHidden = false
            callUberButton.setTitle("Call an Uber", for: [])
            rideCompletedButton.isHidden = true
            
        case .awaitingAccept:
            callUberButton.setTitle("Cancel Uber", for: [])
            callingAnUber = false
            callUberButton.isHidden = false
            rideCompletedButton.isHidden = true
            
        case .accepted:
            rideCompletedButton.isHidden = false
            callUberButton.isHidden = true
            callingAnUber = false
        }
    }
    
    func round(_ double: Double, numOfPlaces: Int) -> Double {
        let divisor = pow(10.0, Double(numOfPlaces))
        
        return ((double * divisor).rounded()) / divisor
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
