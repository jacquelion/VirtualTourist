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
    @IBOutlet weak var mySpinner: UIActivityIndicatorView!
    
    //MARK - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var deletePicturesButton: UIButton!

    var location: Location!
    
    //Hold indexes of selected cells
    var selectedIndexes = [NSIndexPath]()
    //Track when cells are inserted, deleted, or updated.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    //Set default map view
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var longitudeDelta: Double = 0.0
    var latitudeDelta: Double = 0.0
    
    //MARK - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deletePicturesButton.hidden = true
        
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.dataSource = self
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch{}
        
        loadMapView()
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
        
        if (!location.loadedPictures) {
            mySpinner.startAnimating()
            loadPictures(self.location)
        }
    }
    
    func loadPictures(location: Location){
        
        location.loadedPictures = true
        Flickr.sharedInstance.loadFlickrPictures(location) { result, error in
            if let error = error {
                print(error)
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.mySpinner.stopAnimating()
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
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! TaskCancelingCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the collection view cell
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        newCollectionButton.hidden = true
        //User can select and deselect on tap
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
    
    //MARK - Outlet Actions
    @IBAction func done(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
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
        mySpinner.startAnimating()
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            for object in fetchedObjects{
                let picture = object as! Picture
                self.sharedContext.deleteObject(picture)
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
        loadPictures(location)
    }

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
    
    func configureCell(cell: TaskCancelingCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        if let image = picture.pictureImage{
            picture.loadUpdateHandler = nil
            cell.imageView.image = image
            cell.cellSpinner.stopAnimating()
        } else {
            picture.loadUpdateHandler = nil
            cell.cellSpinner.startAnimating()
            let pictureImage = UIImage(named: "picturePlaceholder")

            if let imageURL = NSURL(string: picture.url) {
                Flickr.sharedInstance.taskForImage(imageURL) { data, error in
                    if let error = error {
                        print("error downloading photos from imageURL: \(imageURL) \(error.localizedDescription)")
                        dispatch_async(dispatch_get_main_queue()){
                            cell.imageView.image = UIImage(named: "pictureNoImage")
                            cell.cellSpinner.stopAnimating()
                        }
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            if let pictureImage = UIImage(data: data!)
                            {
                                picture.loadUpdateHandler = { [unowned self] () -> Void in
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.collectionView.reloadItemsAtIndexPaths([indexPath])
                                       // cell.cellSpinner.hidden = true
                                    })
                                }
                                picture.pictureImage = pictureImage
                            }
                            else
                            {
                                picture.loadUpdateHandler = nil
                                cell.imageView.image = UIImage(named: "pictureNoImage")
                                cell.cellSpinner.stopAnimating()
                            }
                        }
                    }
                }
            }
            else {
                cell.imageView.image = UIImage(named: "pictureNoImage")
                cell.cellSpinner.stopAnimating()

            }
        }
    }
    
    
}
