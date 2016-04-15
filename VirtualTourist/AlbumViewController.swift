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

class AlbumViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    var location: Location!
    var picturesToDeleteArray = [Picture]()
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var longitudeDelta: Double = 0.0
    var latitudeDelta: Double = 0.0
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var deletePicturesButton: UIButton!
    
    
    @IBAction func done(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsMultipleSelection = true

        
        loadMapView()
        deletePicturesButton.hidden = true
        //TODO: Check to see if pictures have already been downloaded
        
        do {
            try fetchedResultsController.performFetch()
        } catch{}
        
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadPictures()
    }
    
    func loadPictures(){
        if location.pictures.isEmpty {
            Flickr.sharedInstance.loadFlickrPictures(latitude, longitude: longitude) {
                JSONResult, error in
                if let error = error {
                    print(error)
                } else {
                    
                    if let photosDictionary = JSONResult.valueForKey(Constants.FlickrResponseKeys.Photos) as? [String: AnyObject], photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] {
                        
                        let _ = photoArray.map() { (dictionary: [String: AnyObject]) -> Picture in
                            let picture = Picture(dictionary: dictionary, context: self.sharedContext)
                            
                            picture.location = self.location
                            
                            return picture
                        }
                        
                        // Update the table on the main thread
                        dispatch_async(dispatch_get_main_queue()) {
                            //TODO: Reload Data
                            self.collectionView!.reloadData()
                        }
                    } else {
                        let error = NSError(domain: "Pictures for Location Parsing. Can't find photos in \(JSONResult)", code: 0, userInfo: nil)
                        print(error)
                    }
                }
            }
        }

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
    
    //MARK: - Core Data Convenience 
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //MARK: - Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"id", ascending: true)]
 //       fetchRequest.predicate = NSPredicate(format: "location == %a", self.location)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        return fetchedResultsController
    }()
    
    
    //MARK: Collection View Functions
    let reuseIdentifier = "FlickrImageCell"
    
    //MARK: - UICollectionViewDataSource protocol
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        print(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! TaskCancelingCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the collection view cell
        configureCell(cell, picture: picture)
        
        
        return cell
    }
    
    //TODO: Add delete functionality
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        newCollectionButton.hidden = true
        
        var cell = collectionView.cellForItemAtIndexPath(indexPath)
        if cell?.selected == true {
            cell!.layer.opacity = 0.2
        } else {
            cell!.layer.opacity = 1.0
        }
        
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        picturesToDeleteArray.append(picture)
        
        deletePicturesButton.hidden = false
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell!.layer.opacity = 1
        
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        let indexToDelete = picturesToDeleteArray.indexOf(picture)
        picturesToDeleteArray.removeAtIndex(indexToDelete!)
        
        if picturesToDeleteArray.isEmpty {
            deletePicturesButton.hidden = true
            newCollectionButton.hidden = false
        }
    }
    
    @IBAction func deletePictures(sender: AnyObject) {
        print("IndexPathsForSelectedItems: ", self.collectionView.indexPathsForSelectedItems())
        
        for picture in picturesToDeleteArray {
            sharedContext.deleteObject(picture)
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        deletePicturesButton.hidden = true
        newCollectionButton.hidden = false
        //reload data
        loadPictures()
        collectionView.reloadData()
        
    }
    
    //TODO: Add Delegate Methods (controllerWillChangeContent)
    
    func configureCell(cell: TaskCancelingCollectionViewCell, picture: Picture) {
        var pictureImage = UIImage(named: "picturePlaceholder")

        cell.imageView.image = nil
        
        if picture.url == "" {
            pictureImage = UIImage(named: "pictureNoImage")
        } else if picture.pictureImage != nil {
            pictureImage = picture.pictureImage
        } else {
            let task = Flickr.sharedInstance.taskForImage(picture.url) { data, error in
                
                if let error = error {
                    print("Poster download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    // Create the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the infrmation gets cashed
                    picture.pictureImage = image
                    
                    // update the cell later, on the main thread
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView!.image = image
                    }
                }
            }
            
            // This is the custom property on this cell. See TaskCancelingTableViewCell.swift for details.
        
            cell.taskToCancelifCellIsReused = task
        }
        
        
        cell.imageView!.image = pictureImage
    }
    
    
}
