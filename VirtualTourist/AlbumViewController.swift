//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Jacqueline Sloves on 4/12/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class AlbumViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var longitudeDelta: Double = 0.0
    var latitudeDelta: Double = 0.0
    
    @IBAction func done(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        loadMapView()
        //TODO: Check to see if pictures have already been downloaded
        Flickr.sharedInstance.loadFlickrPictures(latitude, longitude: longitude)
    }
    
    func loadMapView(){
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let savedRegion = MKCoordinateRegion(center: center, span: span)
        print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
        mapView.setRegion(savedRegion, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)
    }
    
    //MARK: Collection View Functions
    let reuseIdentifier = "FlickrImageCell"
    
    //MARK: - UICollectionViewDataSource protocol
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FlickrImageCell
        
        // Use the outlet in our custom class to get a reference to the collection view cell
        
        return cell
    }
    
    
    
}
