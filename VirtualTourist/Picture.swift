//
//  Picture.swift
//  VirtualTourist
//
//  Created by Jacqueline Sloves on 4/11/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import CoreData

class Picture : NSManagedObject {
    
    struct Keys {
        static let id = "id"
        static let title = "title"
        static let url = "url_m"
        static let imagePath = "path"
        static let Location = "location"
    }
    
    @NSManaged var id: NSNumber
    @NSManaged var url: String
    @NSManaged var path: String?
    @NSManaged var location: Location?
    
    var loadUpdateHandler: (() -> Void)?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    override func prepareForDeletion() {
        if let path = path {
            if (NSFileManager.defaultManager().fileExistsAtPath(path)) {
                do
                {
                    try NSFileManager.defaultManager().removeItemAtPath(path)
                }
                catch
                {
                    NSLog("could not delete photo at \(path): \(error)")
                }
            }
        }
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        id = dictionary[Keys.id] as! NSNumber
        url = dictionary[Keys.url] as! String
        path = dictionary[Keys.imagePath] as? String
        location = dictionary[Keys.Location] as? Location
        
    }
    
    static func picturesFromResults(results: [[String:AnyObject]], location: Location) -> NSSet {
        var pictures = NSSet()
        
        var maxPictures = Constants.Flickr.MaxImages
        let originalResultCount = results.count
        var countResults = 0
        var startCount = 0
        
        if(originalResultCount < maxPictures) {
            maxPictures = originalResultCount
        } else {
            startCount = Int(arc4random_uniform(UInt32(originalResultCount - maxPictures)))
        }
        
        for result in results {
            if(countResults < (maxPictures + startCount) && countResults >= startCount) {
                if let imageURL = NSURL(string: result[Keys.url] as! String) {
                    let imagePath = "/\(imageURL.lastPathComponent!)" ?? ""
                    
                    let filteredResult: [String:AnyObject] = [Keys.url : result[Keys.url]!, Keys.imagePath: imagePath, Keys.Location: location, Keys.id: countResults]
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        pictures = pictures.setByAddingObject(Picture(dictionary: filteredResult, context: CoreDataStackManager.sharedInstance().managedObjectContext))
                    }
                }
                else {
                    print("Could not convert photo url to NSURL from photo results")
                }
            }
            countResults += 1
        }
        return pictures
    }
    
    var pictureImage: UIImage? {
        
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(path)
        }
        
        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: path!)
            loadUpdateHandler?()
        }
    }
}