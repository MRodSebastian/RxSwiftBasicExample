//
//  ImageService.swift
//  rxSwift-Test
//
//  Created by Manu Rodríguez on 31/5/18.
//  Copyright © 2018 Streye. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Foundation

enum DownloadableImage{
    case content(image :UIImage)
    case offlinePlaceholder
}

protocol ImageService {
    func imageFromURL(_ url: URL) -> Observable<DownloadableImage>
}

func parseImageURLsfromHTML(_ html: NSString) throws -> [URL]  {
    let regularExpression = try NSRegularExpression(pattern: "<img[^>]*src=\"([^\"]+)\"[^>]*>", options: [])
    
    let matches = regularExpression.matches(in: html as String, options: [], range: NSMakeRange(0, html.length))
    
    return matches.map { match -> URL? in
        if match.numberOfRanges != 2 {
            return nil
        }
        
        let url = html.substring(with: match.range(at: 1))
        
        var absoluteURLString = url
        if url.hasPrefix("//") {
            absoluteURLString = "http:" + url
        }
        
        return URL(string: absoluteURLString)
        }.filter { $0 != nil }.map { $0! }
}

func parseImageURLsfromHTMLSuitableForDisplay(_ html: NSString) throws -> [URL] {
    return try parseImageURLsfromHTML(html).filter {
       return $0.absoluteString.range(of: ".svg.") == nil
    }
}

class ImageServiceAPI: ImageService {
    
    let backgroundHandler :ImmediateSchedulerType
    static let shared = ImageServiceAPI()
    
    private let _imageCache = NSCache<AnyObject, AnyObject>()
    private let _imageDataCache = NSCache<AnyObject, AnyObject>()
    
    private init(){
        _imageCache.totalCostLimit = 20
        _imageDataCache.totalCostLimit = 20
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        operationQueue.qualityOfService = .userInitiated
        backgroundHandler = OperationQueueScheduler(operationQueue: operationQueue)
    }
    
    func forceLazyImageDecompression(_ image :UIImage) -> UIImage {
        #if os(iOS)
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        image.draw(at: CGPoint.zero)
        UIGraphicsEndImageContext()
        #endif
        return image
    }
    
    private func decodeImage(_ imageData :Data) -> Observable<UIImage>{
        return Observable.just(imageData).observeOn(backgroundHandler).map{data in
            guard let image = UIImage(data: imageData) else{
                throw NSError(domain: "com.streye.rxSwift-Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Decoding image error"])
            }
            return self.forceLazyImageDecompression(image)
        }
    }
    
    private func _imageFromURL(_ url :URL) -> Observable<UIImage>{
        return Observable.deferred{
            let imageCached = self._imageCache.object(forKey: url as AnyObject) as? UIImage
            let decodedImage  :Observable<UIImage>
            
            if let image = imageCached{
                decodedImage = Observable.just(image)
            }else{
                let cachedData = self._imageDataCache.object(forKey: url as AnyObject) as? Data
                if let cachedData = cachedData {
                    decodedImage = self.decodeImage(cachedData)
                }else {
                    decodedImage = URLSession.shared.rx.data(request: URLRequest(url: url))
                        .do(onNext: { data in
                            self._imageDataCache.setObject(data as AnyObject, forKey: url as AnyObject)
                        })
                        .flatMap(self.decodeImage)
                }
            }
            return decodedImage.do(onNext: { image in
                self._imageCache.setObject(image, forKey: url as AnyObject)
            })
        }
    }
    
    func imageFromURL(_ url :URL) -> Observable<DownloadableImage>{
        return _imageFromURL(url)
            .map { DownloadableImage.content(image: $0) }
            .startWith(.content(image: UIImage()))
    }
}








