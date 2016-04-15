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
        static let farm = "farm"
        static let id = "id"
        static let secret = "secret"
        static let title = "title"
        static let url = "url_m"
    }
    
    @NSManaged var id: String
    @NSManaged var url: String
    @NSManaged var location: Location?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        id = dictionary[Keys.id] as! String
        url = dictionary[Keys.url] as! String
        
    }
    
    var pictureImage: UIImage? {
        
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(url)
        }
        
        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: url)
        }
    }
}