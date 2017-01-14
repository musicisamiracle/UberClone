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

class RiderViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var rideCompletedButton: UIButton!
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var callUberButton: UIButton!
    let locationManager = CLLocationManager()
    var currentUser: PFUser!
    var callingAnUber = true
    
    enum RequestUpdateType: Int {
        case cancel, complete, refresh
    }

    @IBAction func callUber(_ sender: UIButton) {
        
        if callingAnUber {
            let newLocation = PFObject(className: "RequestedRiders")
            newLocation["user"] = currentUser
            newLocation["completed"] = false
            PFGeoPoint.geoPointForCurrentLocation(inBackground: { [unowned self] (point, error) in
                if error != nil {
                    print(error.debugDescription)
                }
                if let point = point {
                    newLocation["location"] = point
                    newLocation.saveInBackground()
                    sender.setTitle("Cancel Uber", for: [])
                    self.callingAnUber = false
                    self.rideCompletedButton.isHidden = false
                    print("request saved")
                }
            })
        }
        else {
            updateOpenRequests(type: .cancel)
        }
        
    }
    
    @IBAction func completeRide(_ sender: UIButton) {
        updateOpenRequests(type: .complete)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        /*let location = locations[0]
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: center, span: span)
        map.setRegion(region, animated: true)*/
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentUser = PFUser.current()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        map.showsUserLocation = true
        map.isZoomEnabled = true
        map.userTrackingMode = .follow

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logOut" {
            PFUser.logOut()
        }
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        
        updateOpenRequests(type: .refresh)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    func updateOpenRequests(type: RequestUpdateType) {
        
        let query = PFQuery(className: "RequestedRiders")
        query.whereKey("user", equalTo: currentUser)
        query.whereKey("completed", equalTo: false)
        query.addAscendingOrder("createdAt")
        query.getFirstObjectInBackground(block: { [unowned self] (object, error) in
            if error != nil {
                print(error.debugDescription)
            }
            if let request = object {
                switch type {
                case .cancel:
                    request.deleteInBackground()
                    self.callUberButton.setTitle("Call an Uber", for: [])
                    self.callingAnUber = true
                    self.rideCompletedButton.isHidden = true
                    
                case .complete:
                    request["completed"] = true
                    request.saveInBackground()
                    self.rideCompletedButton.isHidden = true
                    self.callUberButton.setTitle("Call an Uber", for: [])
                    self.callingAnUber = true
                
                case .refresh:
                    if request["acceptedBy"] == nil {
                        self.callUberButton.setTitle("Cancel Uber", for: [])
                        self.callingAnUber = false
                        self.rideCompletedButton.isHidden = false
                    }
                    else {
                        print("ride accepted")
                    }
                    
                    
                }
            }
        })
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
