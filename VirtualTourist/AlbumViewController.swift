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
    
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
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
        collectionView.delegate = self
        collectionView.dataSource = self
        
        loadMapView()
        deletePicturesButton.hidden = true
        
        do {
            try fetchedResultsController.performFetch()
        } catch{}
        
        fetchedResultsController.delegate = self
    }
    
    // Layout the collection view
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //Check to see if pictures have already been downloaded, only load pictures if there are none stored already for location.

        if location.pictures.isEmpty {
            loadPictures()
        }
    }
    
    func loadPictures(){
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
                        print("RELOADING DATA")
                        self.collectionView!.reloadData()
                    }
                } else {
                    let error = NSError(domain: "Pictures for Location Parsing. Can't find photos in \(JSONResult)", code: 0, userInfo: nil)
                    print(error)
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
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! TaskCancelingCollectionViewCell
        
        if let index = selectedIndexes.indexOf(indexPath) {
            cell.layer.opacity = 1.0
            selectedIndexes.removeAtIndex(index)
        } else {
            cell.layer.opacity = 0.2
            selectedIndexes.append(indexPath)
        }
        
        if (selectedIndexes.count > 0) {
            newCollectionButton.hidden = true
            deletePicturesButton.hidden = false
        } else {
            newCollectionButton.hidden = false
            deletePicturesButton.hidden = true
        }

    }
    
    
    @IBAction func deletePictures(sender: AnyObject) {
        var picturesToDelete = [Picture]()
        
        for selectedIndex in selectedIndexes {
            picturesToDelete.append(fetchedResultsController.objectAtIndexPath(selectedIndex) as! Picture)
        }
        
        for picture in picturesToDelete {
            sharedContext.deleteObject(picture)
        }
        
        selectedIndexes = [NSIndexPath]()
        
        deletePicturesButton.hidden = true
        newCollectionButton.hidden = false
        
        //reload data
        CoreDataStackManager.sharedInstance().saveContext()
        //loadPictures()
    }
    
    @IBAction func getNewCollection(sender: AnyObject) {
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            for object in fetchedObjects{
                let picture = object as! Picture
                self.sharedContext.deleteObject(picture)
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
        loadPictures()
    }

    //TODO: Add Delegate Methods (controllerWillChangeContent)
    //MARK: - Fetched Results Controller Delegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        //start with empty arrays of each type:
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?){
        switch type{
            
        case .Insert:
            print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    //MARK: - Configure Cell
    
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
