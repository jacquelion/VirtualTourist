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
    
    //MARK: -Shared Instance (Singleton)
    static let sharedInstance = Flickr()

    
    //var pictures = [[String: AnyObject]]()
    var picturesArray = [UIImage]()
    var pictures = NSSet()
    
    var session: NSURLSession
    
    private override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    //MARK: FLICKR API
    func loadFlickrPictures(location: Location, completionHandler: CompletionHandler) -> Void {
        // TODO: Set necessary parameters!
        print("Started search by lat/lon")
        
        let methodParameters: [String: String!] = [
            Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.BoundingBox : bboxString(location.latitude, longitude: location.longitude),
            Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat
        ]
        
        //Please note: I referred to: https://github.com/flyingSarah/VirtualTourist for this function. Many thanks to flyingSarah to getting me unstuck.
        taskForGetMethod(methodParameters) {JSONResult, error in
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                
                if let result = JSONResult.valueForKey(Constants.FlickrResponseKeys.Photos) as? NSDictionary {
                    if let totalPages = result.valueForKey(Constants.FlickrResponseKeys.Pages) as? Int {
                        let pageLimit = min(totalPages, Constants.Flickr.MaxPages)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        let pageNumberString = String(randomPage)
                        var randomPageParameters = methodParameters
                        randomPageParameters[Constants.FlickrParameterValues.Page] = pageNumberString
                        
                        self.taskForGetMethod(randomPageParameters) { randomPageJSONResult, randomPageError in
                            if let randomPageError = randomPageError {
                                completionHandler(result: nil, error: error)
                            } else {
                                if let picturesDictionary = randomPageJSONResult.valueForKey(Constants.FlickrResponseKeys.Photos) {
                                    if let totalPicturesString = picturesDictionary.valueForKey(Constants.FlickrResponseKeys.Total) as? String {
                                        let totalPictures = Int(totalPicturesString)
                                        if (totalPictures > 0) {
                                            if let pictureArray = picturesDictionary.valueForKey("photo") as? [[String:AnyObject]] {
                                                if(pictureArray.count > 0) {
                                                    let pictures = Picture.picturesFromResults(pictureArray, location: location)
                                                    Flickr.sharedInstance.pictures = pictures
                                                    
                                                    completionHandler(result: pictures, error: nil)
                                                } else {
                                                    if let totalPageOnePicturesString = result.valueForKey(Constants.FlickrResponseKeys.Total) as? String {
                                                        let totalPageOnePictures = Int(totalPageOnePicturesString)
                                                        if (totalPageOnePictures > 0) {
                                                            if let pageOnePictureArray = result.valueForKey("photo") as? [[String: AnyObject]] {
                                                                if(pageOnePictureArray.count > 1) {
                                                                    let pictures = Picture.picturesFromResults(pageOnePictureArray, location: location)
                                                                    Flickr.sharedInstance.pictures = pictures
                                                                    completionHandler(result: pictures, error: nil)
                                                                }
                                                                else {
                                                                    completionHandler(result: nil, error: NSError(domain: "loadPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Photos array was empty on Page 1 of Flickr Results."]))
                                                                }
                                                            }
                                                            else {
                                                                completionHandler(result: nil, error: NSError(domain: "loadPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find photo key from Page 1 of Flickr Results."]))
                                                            }
                                                        }
                                                        else {
                                                            completionHandler(result: nil, error: NSError(domain: "loadPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Found 0 photos from Page 1 of Flickr Results."]))
                                                        }
                                                    }
                                                    else {
                                                        completionHandler(result: nil, error: NSError(domain: "loadPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find total photo key from Flickr Results."]))
                                                    }
                                                }
                                            }
                                            else {
                                                completionHandler(result: nil, error: NSError(domain: "loadPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find photo key from Flickr Results."]))
                                            }
                                        }
                                        else {
                                            completionHandler(result: nil, error: NSError(domain: "loadPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Found 0 photos from Flickr Results."]))
                                        }
                                    }
                                    else {
                                        completionHandler(result: nil, error: NSError(domain: "loadPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find total Photos key from Flickr Results."]))
                                    }
                                }
                            }
                        }
                    }
                    else {
                        completionHandler(result: nil, error: NSError(domain: "loadPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find total pages key from Flickr Results."]))
                    }
                }
                else {
                    completionHandler(result: nil, error: NSError(domain: "loadPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not aquire photos from Flickr Result."]))
                }
            }
        }
    }
    
    func taskForImage(imageURL: NSURL, completionHandler: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionTask {
        
        let request = NSURLRequest(URL: imageURL)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Download Error: ", error)
                let newError = Flickr.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    
    //MARK: Helpers
    
    func bboxString(latitude: Double, longitude: Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLatRange.1)
        
        print("\(minimumLon), \(minimumLat), \(maximumLon), \(maximumLat)")
        
        return "\(minimumLon), \(minimumLat), \(maximumLon), \(maximumLat)"
    }

    func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
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

    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
}