//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Jacqueline Sloves on 4/11/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import Foundation

class Flickr : NSObject {
    
    typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
    
    var pictures = [[String: AnyObject]]()
    var picturesArray = [UIImage]()
    
    var session: NSURLSession
    
    private override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    //MARK: FLICKR API
    func loadFlickrPictures(latitude: Double, longitude: Double, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        // TODO: Set necessary parameters!
        print("Started search by lat/lon")
        
        let methodParameters: [String: String!] = [
            Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.BoundingBox : self.bboxString(latitude, longitude: longitude),
            Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat
        ]
        //self.displayImageFromFlickrBySearch(methodParameters)
        
        let session = NSURLSession.sharedSession()
        let url = flickrURLFromParameters(methodParameters)
        print("URL", url)
        let request = NSURLRequest(URL: url)
        print("REQUEST: ", request)
        let task = session.dataTaskWithRequest(request) {data, response, error in
            
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                print("Step 3 - taskForResource's completionHandler is invoked.")
                Flickr.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        
        task.resume()
        print("TASK: ", task)
        return task
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLatRange.1)
        
        print("\(minimumLon), \(minimumLat), \(maximumLon), \(maximumLat)")
        
        return "\(minimumLon), \(minimumLat), \(maximumLon), \(maximumLat)"
    }
    
    func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionTask {
        
        let url = NSURL(fileURLWithPath: filePath)
        
        print(url)
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                print(error)
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    
    }
    
//    private func displayImageFromFlickrBySearch(methodParameters: [String:AnyObject]) {
//        print("started Display Image From Flickr By Search.")
//        
//        let session = NSURLSession.sharedSession()
//        let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
//        
//        let task = session.dataTaskWithRequest(request) { (data, response, error) in
//            
//            func displayError(error:String) {
//                print(error)
//                //TODO: performUIUpdatesOnMain
//            }
//            
//            guard (error == nil) else {
//                displayError("There was an error with your request: \(error)")
//                return
//            }
//            
//            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where
//                statusCode >= 200 && statusCode <= 299 else {
//                    displayError("Your request returned a status code other than 2xx!")
//                    return
//            }
//            
//            guard let data = data else {
//                displayError("No data was returned by the request.")
//                return
//            }
//            
//            let parsedResult: AnyObject!
//            do {
//                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
//                print("Parsed Result: ", parsedResult)
//            } catch {
//                displayError("Could not parse the data as JSON: \(data)")
//                return
//            }
//            
//            if let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject], photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] {
//                
//                self.pictures = photoArray
//                
//                guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
//                    displayError("Cannot find key \(Constants.FlickrResponseKeys.Pages)")
//                    return
//                }
//                let pageLimit = min(totalPages, 40)
//                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
//                
//                if photoArray.count == 0 {
//                    displayError("No photos were found. search again.")
//                    return
//                } else {
//                    print(photosDictionary)
//                    
//                    for photo in photoArray {
//                        
//                        guard let imageURLString = photo[Constants.FlickrResponseKeys.MediumURL] as? String else {
//                            displayError("Problem with URL")
//                            return
//                        }
//                        
//                        let imageURL = NSURL(string:imageURLString)
//                        
//                        if let imageData = NSData(contentsOfURL: imageURL!) {
//                            
//                            let image = UIImage(data: imageData)
//                            self.picturesArray.append(image!)
//                            
//                        } else {
//                            displayError("Image does not exist.")
//                        }
//                    }
//                }
//                
//            }
//        }
//        
//        task.resume()
//    }
    
    
    // Parsing the JSON
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandler) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            print("Parsed Result: ", parsedResult)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            print("Step 4 - parseJSONWithCompletionHandler is invoked.")
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }

    //MARK: -Shared Instance (Singleton)
    static let sharedInstance = Flickr()
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }

}