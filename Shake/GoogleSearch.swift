//
//  GoogleSearch.swift
//  Shake
//
//  Created by Antonio Padilla on 1/21/17.
//  Copyright © 2017 Tony Padilla. All rights reserved.
//

import Foundation

// for diffrentiating which API sevice is used
enum SearchType {
    case NEARBY
    case CUSTOM
    case DETAIL
    case PHOTO
}

// search parameters to append to request url
typealias Parameters = [String: String]


/*
 *  Struct containing a wrapper for Google Api requests.
 *  URL for request created at initialization time based on SearchType and Parameters
 *
 */
public struct GoogleSearch {
    
    var type: SearchType?
    var params: Parameters?
    var url: String?
    private let httpMethod: String = "GET"
    
    // the following urls will be used for an api request depending on SearchType
    private var nearbyURL: String =
    "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    private var detailURL: String =
    "https://maps.googleapis.com/maps/api/place/details/json"
    private var photoURL: String =
    "https://maps.googleapis.com/maps/api/place/photo"
    
    init(type: SearchType, parameters: Parameters?) {
        self.type = type
        self.params = parameters
        switch type {
            case .CUSTOM: self.url = ""; break
            case .DETAIL: self.url = detailURL; break
            case .NEARBY: self.url = nearbyURL; break
            case .PHOTO: self.url = photoURL; break
        }
       self.appendParametersToURL()
    }
    
    // helper function used for appending search parameters to url
    private mutating func appendParametersToURL() {
        if params == nil { return }
        var paramsArr: [String] = []
        for parameter in self.params! {
            paramsArr.append("\(parameter.key)=" + "\(parameter.value)")
        }
        let paramsAsString: String = paramsArr.joined(separator: "&")
        if url == nil { return }
        self.url! = self.url!.appendingFormat("?%@", paramsAsString)
    }
    
    
    /*
     *  Creates a task that retrieves the contents of the call to the
     *  Google API specified by the url created based on search type.
     *
     *  - parameter session: api for downloading content (minimum requirements)
     *  - parameter handler: method, specified by controller that instiated
     *    search struct used, to manipulate data retrieved upon task completion
     */
    mutating func makeRequest(_ session: URLSession,
                              handler: @escaping (Data?) -> Void) {
        
        let urlPath = URL(string: self.url!)
        if let fullPath = urlPath {
            let request: NSMutableURLRequest = NSMutableURLRequest(url: fullPath)
            request.httpMethod = self.httpMethod
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30
            let dataTask = session.dataTask(with: request as URLRequest) {
                (data: Data?, response: URLResponse?, error: Error?) -> Void in
                guard let _ = response as? HTTPURLResponse,
                    let receivedData = data
                    else {
                        handler(nil)
                        return
                }
                handler(receivedData)
            }
            dataTask.resume()
        } else {
            handler(nil)
        }
    }
    
    /* there is one use case where an http request must be made to a custom url 
     * MUST be called before making request if search type is .custom
     */
    mutating func setCustomURL(_ url: String?) {
        if url == nil { self.url = " " }
        if url!.range(of: "https:") == nil {
            self.url = "https:" + url!
        } else {
            self.url = url!
        }
    }
    
}
