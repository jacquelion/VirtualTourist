//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Jacqueline Sloves on 4/11/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import Foundation

class Flickr {
    
    private init() {
    
    }
    
    //MARK: FLICKR API
    func loadFlickrPictures(latitude: Double, longitude: Double) {
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
        self.displayImageFromFlickrBySearch(methodParameters)
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLatRange.1)
        
        print("\(minimumLon), \(minimumLat), \(maximumLon), \(maximumLat)")
        
        return "\(minimumLon), \(minimumLat), \(maximumLon), \(maximumLat)"
    }
    
    private func displayImageFromFlickrBySearch(methodParameters: [String:AnyObject]) {
        print("started Display Image From Flickr By Search.")
        
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func displayError(error:String) {
                print(error)
                //TODO: performUIUpdatesOnMain
            }
            
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where
                statusCode >= 200 && statusCode <= 299 else {
                    displayError("Your request returned a status code other than 2xx!")
                    return
            }
            
            guard let data = data else {
                displayError("No data was returned by the request.")
                return
            }
            
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                print("Parsed Result: ", parsedResult)
            } catch {
                displayError("Could not parse the data as JSON: \(data)")
                return
            }
            
            if let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject], photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] {
                
                guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                    displayError("Cannot find key \(Constants.FlickrResponseKeys.Pages)")
                    return
                }
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                
                if photoArray.count == 0 {
                    displayError("No photos were found. search again.")
                    return
                } else {
                    
                    guard let imageURLString = photosDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
                        displayError("Problem with URL")
                        return
                    }
                    
                    let imageURL = NSURL(string:imageURLString)
                    if let imageData = NSData(contentsOfURL: imageURL!) {
                        
                        // FlickrImageCell.image.image = UIImage(data: imageData)
                    } else {
                        displayError("Image does not exist.")
                    }
                    
                }
            }
        }
        
        task.resume()
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

}