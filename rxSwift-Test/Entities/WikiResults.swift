//
//  WikiResults.swift
//  rxSwift-Test
//
//  Created by Manu Rodríguez on 31/5/18.
//  Copyright © 2018 Streye. All rights reserved.
//

import Foundation

func apiError(_ error: String) -> NSError {
    return NSError(domain: "WikipediaAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
}

public let WikipediaParseError = apiError("Error during parsing")

struct WikiResults :CustomDebugStringConvertible{
    
    let title :String
    let description :String
    let URL :URL
    
    var debugDescription: String{
        return "[\(title)](\(URL))"
    }
    
    static func parseJSON(_ json :[AnyObject]) throws -> [WikiResults]{
        let rootArrayTyped: [[AnyObject]] = json.compactMap { $0 as? [AnyObject] }
        
        guard rootArrayTyped.count == 3 else {
            throw WikipediaParseError
        }
        
        let (titles, descriptions, urls) = (rootArrayTyped[0], rootArrayTyped[1], rootArrayTyped[2])
        
        let titleDescriptionAndUrl: [((AnyObject, AnyObject), AnyObject)] = Array(zip(zip(titles, descriptions), urls))
        
        return try titleDescriptionAndUrl.map { result -> WikiResults in
            let ((title, description), url) = result
            
            guard let titleString = title as? String,
                let descriptionString = description as? String,
                let urlString = url as? String,
                let URL = Foundation.URL(string: urlString) else {
                    throw WikipediaParseError
            }
            
            return WikiResults(title: titleString, description: descriptionString, URL: URL)
        }
    }
    
}
