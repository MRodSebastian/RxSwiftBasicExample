
//
//  WikipediaService.swift
//  rxSwift-Test
//
//  Created by Manu Rodríguez on 31/5/18.
//  Copyright © 2018 Streye. All rights reserved.
//

import RxSwift
import RxCocoa
import Foundation

protocol WikiAPI {
    func getResults() -> Observable<[WikiResults]>
}

class WikipediaService{
    
    let backgroundHandler :ImmediateSchedulerType
    static let shared = WikipediaService()
    
    private init(){
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        operationQueue.qualityOfService = .userInitiated
        backgroundHandler = OperationQueueScheduler(operationQueue: operationQueue)
    }
    
    private func JSON(_ url :URL) -> Observable<Any>{
        return URLSession.shared.rx.json(url: url)
    }
    
    
    func getResults(_ query :String) -> Observable<[WikiResults]>{
        let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let urlContent = "http://en.wikipedia.org/w/api.php?action=opensearch&search=\(escapedQuery)"
        let url = URL(string: urlContent)!
        
        
        
        return JSON(url).observeOn(backgroundHandler).map{json in
            guard let json = json as? [AnyObject] else{
                throw NSError(domain: "com.streye.rxSwift-Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Parsing error"])
            }
            
            return try WikiResults.parseJSON(json)
        }.observeOn(MainScheduler.instance)
    }
    
    func articleContent(_ searchResult :WikiResults) -> Observable<WikiPage>{
        let escapedPage = searchResult.title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        guard let url = URL(string: "http://en.wikipedia.org/w/api.php?action=parse&page=\(escapedPage)&format=json") else{
            return Observable.error(NSError(domain: "com.streye.rxSwift-Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Can't create url"]))
        }
        
        return JSON(url).map{result in
            guard let json = result as? NSDictionary else {
                throw NSError(domain: "com.streye.rxSwift-Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Parsing error"])
            }
            
            return try WikiPage.parseJSON(json)
        }.observeOn(MainScheduler.instance)
    }
}
