//
//  WIkiPage.swift
//  rxSwift-Test
//
//  Created by Manu Rodríguez on 31/5/18.
//  Copyright © 2018 Streye. All rights reserved.
//

import RxSwift
import Foundation

struct WikiPage {
    let title   :String
    let text    :String
    
    static func parseJSON(_ json: NSDictionary) throws -> WikiPage{
        guard
            let parse = json.value(forKey: "parse"),
            let title = (parse as AnyObject).value(forKey: "title") as? String,
            let t = (parse as AnyObject).value(forKey: "text"),
            let text = (t as AnyObject).value(forKey: "*") as? String else {
                throw apiError("Error parsing page content")
        }
        return WikiPage(title: title, text: text)
    }
}
