//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Jacqueline Sloves on 4/15/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import Foundation
import UIKit

extension Flickr {

    
    //MARK --- Get
    func taskForGetMethod(parameters: [String : AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask
    {
        //build the url and configure the request
        let urlString = Constants.Flickr.BaseURL + Flickr.escapedParameters(parameters)
        //print("attempting to request the following url:\n  \(urlString)")
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        //make the request
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            
            //parse and use the data (happens in completion handler)
            if let error = downloadError
            {
                let newError = Flickr.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            }
            else
            {
                Flickr.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        
        task.resume()
        return task
    }
    
    
    //MARK --- Helpers
    
    //given a response with error, see if a status_message is returned, otherwise return the previous error
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError?) -> NSError
    {
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject]
        {
            if let errorMessage = parsedResult[Constants.FlickrResponseKeys.Status] as? String
            {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                if let errorCode = parsedResult[Constants.FlickrResponseKeys.Code] as? Int
                {
                    return NSError(domain: "Flickr Parse Error", code: errorCode, userInfo: userInfo)
                }
                
                return NSError(domain: "Flickr Parse Error", code: 0, userInfo: userInfo)
            }
        }
        
        return error!
    }

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
            if let _ = parsedResult?.valueForKey(Constants.FlickrResponseKeys.Code) as? String {
                let newError = errorForData(data, response: nil, error: nil)
                completionHandler(result: nil, error: newError)
            } else {
                completionHandler(result: parsedResult, error: nil)
            }
        }
    }

    

    //given a dictionary of parameters, convert to a string for a url
    class func escapedParameters(parameters: [String : AnyObject]) -> String
    {
        let queryItems = parameters.map { NSURLQueryItem(name: $0, value: $1 as? String) }
        let components = NSURLComponents()
        
        components.queryItems = queryItems
        return components.percentEncodedQuery ?? ""
    }



}