//
//  Search.swift
//  Shake
//
//  Created by Tony Padilla on 5/30/16.
//  Copyright © 2016 Tony Padilla. All rights reserved.
//

import Foundation
import CoreLocation
import GoogleMaps
import Alamofire

// MARK: - Google API URI stuff
let URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
let LOCATION = "location="
let RADIUS = "radius="
var KEY = "key="
let RANK = "rankby="

let CUSTOMURL = "https://www.googleapis.com/customsearch/v1?"
let DETAILURL =
    "https://maps.googleapis.com/maps/api/place/details/json?"

// MARK: - SEARCH
public class Search {
    
    private static let appDelegate: AppDelegate? =
        UIApplication.sharedApplication().delegate as? AppDelegate
    
    static func getLocationsURL(query: String, location: CLLocation?) -> String? {
        let coordinate: CLLocationCoordinate2D?
        if let manager: CLLocation = location {
            coordinate = manager.coordinate
            if let coords = coordinate {
                if let apiKey = appDelegate?.getApiKey() {
                    let latitude = coords.latitude
                    let longitude = coords.longitude
                    let result =
                        "\(URL)\(LOCATION)\(latitude),\(longitude)&\(RANK)distance" +
                            "&type=\(query)&\(KEY)\(apiKey)"
                    return result
                }
            }
        }
        return nil
    }
    
    private static func fetchImages(query: String, completion: (NSDictionary?) -> Void) {
        if let apiKey = appDelegate?.getApiKey() {
            let params: [String : String] =
                ["q": "\(query)",
                 "cx": "016392490542402719401:qnjrofkd7nk",
                 "start": "1", "imgSize": "medium", "imgType": "photo", "num": "2",
                 "safe": "off", "searchType": "image",
                 "key":"\(apiKey)"]
            
            Alamofire.request(.GET, CUSTOMURL, parameters: params, encoding: .URL)
                .responseJSON{ (response) -> Void in
                    dispatch_async(dispatch_get_main_queue(), {
                        guard response.result.isSuccess else {
                            print("Error Fetching Results: \(response.result.error)")
                            completion(nil)
                            return
                        }
                        guard let value = response.result.value
                            as? NSDictionary else {
                                print("Bad Data")
                                completion(nil)
                                return
                        }
                        completion(value)
                    })
            }
        }
    }
    
    static func detailQuery(byPlaceID id: String, returnData: (NSDictionary?) -> Void) {
        if let apiKey = appDelegate?.getApiKey() {
            let params: [String: String] =
                ["placeid": "\(id)", "key": "\(apiKey)"]
            
            Alamofire.request(.GET, DETAILURL, parameters: params, encoding: .URL)
                .responseJSON{
                    (response) -> Void in
                    guard response.result.isSuccess else {
                        print("Error Fetching Details: \(response.result.error)")
                        returnData(nil)
                        return
                    }
                    guard let value = response.result.value as? NSDictionary else {
                        print("Bad Data")
                        return
                    }
                    returnData(value)
            }
        }
    }
    
    static func imageQuery(location: String, atIndex: Int, list: [String?], imageView: UIImageView) {
        let name: String = (list.count > atIndex) ?
            "\(list[atIndex]!)":"\(location)"
        let query: String?
        query = (name.contains(location)) ? "\(name)": "\(name) " + "\(location)"
        
        if let search = query {
            self.fetchImages(search, completion: {
                (data) -> Void in
                if let data = data {
                    let result: [NSDictionary]? = data["items"] as? [NSDictionary]
                    if let result = result {
                        let desired: NSDictionary =
                            (result.count > 0) ? result[0] as NSDictionary:[:]
                        let url: String? = (desired.count > 0) ?
                            desired["link"] as? String: ""
                        if let URL = url {
                            self.setImage(URL, image: imageView)
                        }
                    }
                }
            })
        }
    }
    
    private static func setImage(url: String, image: UIImageView) {
        //TODO: delegate get requests to background queues
        // delegate UI updates to MAIN queue
        dispatch_async(dispatch_get_main_queue(), {
            Alamofire.request(.GET, url).responseImage(completionHandler: {
                response in
                //TODO: error handling
                if let error = response.result.error {
                    print("Image Request: \(error.description)")
                }
                if let imagen = response.result.value {
                    image.image = imagen
                    image.clipsToBounds = true
                    image.contentMode = .ScaleAspectFill
                }
            })
        })
    }
}

// MARK: - MAIN VIEW CONTROLLER EXTENSION

extension ViewController {
    
    // MARK: - LOCATIONS SEARCH
    
    func parseResults(theJSON: Array<NSDictionary>?) {
        let array: [String?]
        if let results = theJSON {
            array = results.map({($0["name"] as? String)})
            self.results = results
            self.locationNames = array
            //print(results)
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        readyToSegue = true
        print("done")
    }
    
    func networkTaskHandler(data: NSData?, response: NSURLResponse?,
                            error: NSError?) {
        do {
            if let data = data {
                let theJSON =
                    try NSJSONSerialization
                        .JSONObjectWithData(data, options: .MutableContainers)
                        as! NSMutableDictionary
                
                let results = theJSON["results"] as? Array<NSDictionary>
                parseResults(results)
            }
        } catch {
            // TODO: Handle Errors
            print("Handler Error: \(error)")
        }
    }
    
    
    func googleSearch(uri: String) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let session =
            NSURLSession(configuration: NSURLSessionConfiguration
                .defaultSessionConfiguration())
        
        let url: NSURL? = NSURL(string: uri)
        if let URL = url {
            let networkTask =
                session.dataTaskWithURL(URL, completionHandler: networkTaskHandler)
            networkTask.resume()
        }
    }

}










