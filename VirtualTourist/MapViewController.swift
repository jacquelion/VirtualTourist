//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Jacqueline Sloves on 4/11/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mySpinner: UIActivityIndicatorView!
    
    var longitude : Double = 0.0
    var latitude : Double = 0.0
    
    var editingMap : Bool = false
    
    var locations = [Location]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        deleteLabel.hidden = true
        
        restoreMapRegion(true)
        self.mapView.delegate = self
        
        //enable long press to drop a pin
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(_:)))
        uilgr.minimumPressDuration = 0.8
        mapView.addGestureRecognizer(uilgr)
        
        mySpinner.startAnimating()
        view.alpha = 0.5
        
        //Core Data: get all previously placed pins
        loadMapAnnotations()
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    func loadMapAnnotations(){
        locations = fetchAllLocations()
        
        for i in locations{
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: i.latitude, longitude: i.longitude)
            mapView.addAnnotation(annotation)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Core Data Convenience.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func fetchAllLocations() -> [Location] {
        let fetchRequest = NSFetchRequest(entityName: "Location")
        do {
            print("Fetch Request: \(fetchRequest)")
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Location]
        } catch let error as NSError {
            print("Error in fetchAllLocations(): \(error)")
            return [Location]()
        }
        
    }
    
    @IBAction func beginEdit(sender: AnyObject) {
        if deleteLabel.hidden == false {
            deleteLabel.hidden = true
            editButton.title = "Edit"
            editingMap = false
            view.alpha = 1.0
        } else {
            deleteLabel.hidden = false
            editButton.title = "Done"
            editingMap = true
            view.alpha = 0.5
        }
        //TODO: Shift view up, fix ui
    }
    
    // MARK: - Save the zoom level helpers
    
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
    
    //MARK: -Drop A Pin Functions
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if editingMap == false {
            switch gestureRecognizer.state {
            case .Began:
                let touchPoint = gestureRecognizer.locationInView(mapView)
                let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
                latitude = Double(newCoordinates.latitude)
                longitude = Double(newCoordinates.longitude)
                print("Longitude: ", longitude, ", Latitude: ", latitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = newCoordinates
                mapView.addAnnotation(annotation)

            case .Ended:
                
                    //CORE DATA
                    var dictionary = [String : AnyObject]()
                    
                    dictionary[Location.Keys.Latitude] = latitude
                    dictionary[Location.Keys.Longitude] = longitude
                    
                    let locationToBeAdded = Location(dictionary: dictionary, context: sharedContext)
                    
                    self.locations.append(locationToBeAdded)
                    CoreDataStackManager.sharedInstance().saveContext()
            default:
                break
            }
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
    
    //MARK: -Segue in response to touch
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView){
        let coordinate = view.annotation?.coordinate

        if editingMap == false {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let vc = storyboard.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController

            
            vc.latitude = (view.annotation?.coordinate.latitude)!
            vc.longitude = (view.annotation?.coordinate.longitude)!
            vc.latitudeDelta = self.mapView.region.span.latitudeDelta
            vc.longitudeDelta = self.mapView.region.span.longitudeDelta
            
            for location in locations {
                if location.latitude == (coordinate!.latitude) && location.longitude == (coordinate!.longitude) {
                    vc.location = location
                    break
                }
            }
            
            self.presentViewController(vc, animated: true, completion: nil)
        } else {
            print("Deleted Pin")
            for location in locations {
                if location.latitude == (coordinate!.latitude) && location.longitude == (coordinate!.longitude) {
                    sharedContext.deleteObject(location)
                    CoreDataStackManager.sharedInstance().saveContext()
                    let annotationToRemove = view.annotation
                    self.mapView.removeAnnotation(annotationToRemove!)
                    break
                }
            }
        }
    }
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        mySpinner.hidden = true
        mySpinner.stopAnimating()
        view.alpha = 1.0
    }
    
    
}


