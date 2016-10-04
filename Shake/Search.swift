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

// MARK: - SEARCH
public struct Search {
    
    // MARK: - Google API URI
    private static let URL: URLConvertible =
    "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
    
    private static let CUSTOMURL: URLConvertible =
    "https://www.googleapis.com/customsearch/v1?"
    
    private static let DETAILURL: URLConvertible =
    "https://maps.googleapis.com/maps/api/place/details/json?"
    
    private static let PHOTOURL: URLConvertible =
    "https://maps.googleapis.com/maps/api/place/photo?"
    
    weak fileprivate static var appDelegate: AppDelegate? =
        UIApplication.shared.delegate as? AppDelegate
    
    private static func GSearchRequest(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        parser: @escaping ([NSDictionary]?) -> Void) {
        Alamofire
        .request(url,
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default)
                .responseJSON {
                (response) -> Void in
                guard response.result.isSuccess else {
                    print("Error Fetching Details: \(response.result.error)")
                    parser(nil)
                    return
                }
                guard let value = response.result.value as? NSDictionary else {
                    print("Bad Data")
                    return
                }
                parser(value["results"] as? [NSDictionary])
            }
    }
    
    // MARK: - Search methods
    static func GSearh(_ query: String, location: CLLocation?,
                       parser: @escaping ([NSDictionary]?)->Void,
                       host: UIViewController?) {
        if let current_vc = host {
            if !Reachability.isConnected() {
                current_vc.view.offlineViewAppear()
            }
        }
        let coordinate: CLLocationCoordinate2D?
        if let manager: CLLocation = location {
            coordinate = manager.coordinate
            if let coords = coordinate {
                if let apiKey = appDelegate?.getApiKey() {
                    let latitude = coords.latitude
                    let longitude = coords.longitude
                    let params: Parameters =
                        ["location":"\(latitude),\(longitude)",
                         "rankby":"distance", "type":"\(query)",
                         "key":"\(apiKey)"]
                    GSearchRequest(URL, method: .get, parameters: params,
                                   parser: parser)
                }
            }
        }
    }
    
    static func detailQuery(
        byPlaceID id: String,
        atIndex: Int,
        returnData: @escaping (NSDictionary?, Int?) -> Void) {
        
        if let apiKey = appDelegate?.getApiKey() {
            let params: Parameters =
                ["placeid": "\(id)", "key": "\(apiKey)"]
            Alamofire.request(
                DETAILURL,
                method: .get,
                parameters: params,
                encoding: URLEncoding.default)
                .responseJSON{
                    (response) -> Void in
                    guard response.result.isSuccess else {
                        print("Error Fetching Details: \(response.result.error)")
                        returnData(nil, nil)
                        return
                    }
                    guard let value = response.result.value as? NSDictionary else {
                        print("Bad Data")
                        return
                    }
                    returnData(value, atIndex)
            }
        }
    }
    
    static func retrieveImageByReference(ref: String,
                                         target: UIImageView,
                                         maxWidth: Int) {
        if let apiKey = appDelegate?.getApiKey() {
            let params: Parameters =
                [
                 "maxwidth": "\(maxWidth)",
                 "photoreference":"\(ref)",
                 "key":"\(apiKey)"]
            
            Alamofire.request(
                PHOTOURL,
                method: .get,
                parameters: params,
                encoding: URLEncoding.default)
            .responseImage {
                (response) -> Void in
                guard response.result.isSuccess else {
                    print("Error: \(response.result.error)")
                    return
                }
                DispatchQueue.main.async {
                    target.image = response.result.value
                }
            }
        }
    }
}







