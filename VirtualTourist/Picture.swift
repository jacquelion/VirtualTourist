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
    
    
    @NSManaged var url: String
    @NSManaged var location: Location
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        url = dictionary[Keys.url] as! String
        
    }
}



//Example Response:
//{
//farm = 2;
//"height_m" = 500;
//id = 26380583625;
//isfamily = 0;
//isfriend = 0;
//ispublic = 1;
//owner = "94651762@N04";
//secret = c436635e12;
//server = 1543;
//title = "Pier39 #pier39 #pier #flag #seagull #flags #sf #sfo #sanfrancisco #carlifornia #usa";
//"url_m" = "https://farm2.staticflickr.com/1543/26380583625_c436635e12.jpg";
//"width_m" = 400;
//}