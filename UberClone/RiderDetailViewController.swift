//
//  RiderDetailViewController.swift
//  UberClone
//
//  Created by Dane Thomas on 1/13/17.
//  Copyright © 2017 Parse. All rights reserved.
//


/* create an annotation that shows rider location, also have driver location visible
   accepting the ride opens directions in apple maps */

import UIKit
import MapKit
import Parse

class RiderDetailViewController: UIViewController {

    @IBOutlet var map: MKMapView!
    @IBOutlet var acceptButton: UIButton!
    var rideRequest: PFObject?

    @IBAction func acceptRider(_ sender: UIButton) {
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print(rideRequest)
        
        map.showsUserLocation = true
        map.isZoomEnabled = true
        
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
