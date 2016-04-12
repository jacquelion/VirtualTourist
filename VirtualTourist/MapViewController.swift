//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Jacqueline Sloves on 4/11/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        deleteLabel.hidden = true
        restoreMapRegion(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func beginEdit(sender: AnyObject) {
        if deleteLabel.hidden == false {
            deleteLabel.hidden = true
            editButton.title = "Edit"
        } else {
            deleteLabel.hidden = false
            editButton.title = "Done"
        }
        //TODO: Shift view up, fix ui
    }

    // MARK: - Save the zoom level helpers
    
    // Here we use the same filePath strategy as the Persistent Master Detail
    // A convenient property
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
}

/**
 *  This extension comforms to the MKMapViewDelegate protocol. This allows
 *  the view controller to be notified whenever the map region changes. So
 *  that it can save the new region.
 */

extension MapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
}
