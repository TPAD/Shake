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

// MARK: - Google API URIs
let URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
let LOCATION = "location="
let RADIUS = "radius="
var KEY = "key="
let RANK = "rankby="

let CUSTOMURL = "https://www.googleapis.com/customsearch/v1?"
let Q = "q="
let NUM = "&num="   //NUMBER OF RESULTS 1-10
let START = "&start=" // offset from search results 1-100
let IMGSIZE = "&imgsize=medium"
let TYPE = "&searchType=image"
let FILE = "&filetype=jpg"
let CX = "&cx="

let STURL = "https://maps.googleapis.com/maps/api/streetview?"
let SIZE = "size="

// MARK: - SEARCH
public class Search {
    
    private static let appDelegate: AppDelegate? =
        UIApplication.sharedApplication().delegate as? AppDelegate
    
    static func getImageSearchURL(query: String, name: String) -> String {
        let engine: String = "016392490542402719401:wtwc4bgjdok"
        let resultNum: Int = 5
        let offset: Int = 1
        let result: String =
            "\(CUSTOMURL)\(Q)\(query)%20\(name)\(NUM)\(resultNum)\(START)\(offset)\(IMGSIZE)\(TYPE)" +
            "\(FILE)\(CX)\(engine)"
        return result
    }
    
    static func getLocationsURL(query: String, location: CLLocation?) -> String? {
        let coordinate: CLLocationCoordinate2D?
        if let manager: CLLocation = location {
            coordinate = manager.coordinate
            if let coords = coordinate {
                if let apiKey = appDelegate?.getApiKey() {
                    let latitude = coords.latitude
                    let longitude = coords.longitude
                    //let radius: Int = 300
                    let result =
                        "\(URL)\(LOCATION)\(latitude),\(longitude)&\(RANK)distance" +
                            "&type=\(query)&\(KEY)\(apiKey)"
                    return result
                }
            }
        }
        return nil
    }
    
    static func getStreetViewsURL(coords: CLLocationCoordinate2D?, size: CGSize)
        -> String? {
            if let coords = coords {
                let lat: CLLocationDegrees = coords.latitude
                let lng: CLLocationDegrees = coords.longitude
                let width: Int = Int(size.width)
                let height: Int = Int(size.height)
                if let apiKey = appDelegate?.getApiKey() {
                    let result =
                        "\(STURL)\(SIZE)\(width)x\(height)" +
                            "&\(LOCATION)\(lat),\(lng)&\(KEY)\(apiKey)"
                    return result
                }
            }
            return nil
    }
    
    static func parseImageDataJSON(theJSON: Array<NSDictionary>?) {
        print(theJSON)
        if let results = theJSON {
            print(results)
        }
    }
    
    static func taskHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
        do {
            if let data = data {
                let theJSON =
                    try NSJSONSerialization
                        .JSONObjectWithData(data, options: .MutableContainers)
                        as! NSMutableDictionary
                print(theJSON)
                let results = theJSON["results"] as? Array<NSDictionary>
                parseImageDataJSON(results)
            }
        } catch {
            print("Image Results Error: \(error)")
        }
    }
    
    static func googleImageSearch(url: String) {
        let session =
            NSURLSession(configuration: NSURLSessionConfiguration
                .defaultSessionConfiguration())
        
        let url: NSURL? = NSURL(string: url)
        
        if let URL = url {
            let networkTask =
                session.dataTaskWithURL(URL, completionHandler: taskHandler)
            networkTask.resume()
        }

    }
}

// MARK: - MAIN VIEW CONTROLLER EXTENSION

extension ViewController {
    
    // MARK: - LOCATIONS SEARCH
    
    func parseResults(theJSON: Array<NSDictionary>?) {
        let array: [String?]
        if let results = theJSON {
            array = results.map({($0["name"] as? String)})
            //self.imageMetaData = array
            self.results = results
            self.locationNames = array
            //print(array)
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


// MARK: - DESTINATIONS VIEW CONTROLLER EXTENSION
extension DestinationViewController {
    

}










