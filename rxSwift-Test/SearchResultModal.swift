//
//  SearchResultModal.swift
//  rxSwift-Test
//
//  Created by Manu Rodríguez on 31/5/18.
//  Copyright © 2018 Streye. All rights reserved.
//

import RxSwift
import RxCocoa

class SearchResultsModal{
    
    let searchResult :WikiResults
    var title :Driver<String>
    var imageURLs :Driver<[URL]>
    
    let API = WikipediaService.shared
    let backgroundHandler :ImmediateSchedulerType?
    
    init(searchResult: WikiResults) {
        self.searchResult = searchResult
        
        self.title = Driver.never()
        self.imageURLs = Driver.never()
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        operationQueue.qualityOfService = .userInitiated
        backgroundHandler = OperationQueueScheduler(operationQueue: operationQueue)
        
        let URLs = configureURL()
        self.imageURLs = URLs.asDriver(onErrorJustReturn: [])
        self.title = configureTitle(URLs).asDriver(onErrorJustReturn: "Error during fetching")
    }
    
    func configureTitle(_ imageURLs :Observable<[URL]>) -> Observable<String>{
        let searchResult = self.searchResult
        let loadingValues :[URL]? = nil
        
        return imageURLs.map(Optional.init).startWith(loadingValues).map{URLs in
            if let URLs = URLs{
                return "\(searchResult.title) (\(URLs.count) pictures)"
            }else{
                return "\(searchResult.title) (loading…)"
            }
        }
    }
    
    func configureURL() -> Observable<[URL]>{
        let searchResult = self.searchResult
        return API.articleContent(searchResult).observeOn(backgroundHandler!).map{page in
            do{
                let a = try parseImageURLsfromHTMLSuitableForDisplay(page.text as NSString)
                return a
            }catch let error{
                print(error.localizedDescription)
                return []
            }
        }
    }
    
}
