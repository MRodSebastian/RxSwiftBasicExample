//
//  CollectionViewImageCell.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 4/4/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public class CollectionViewImageCell: UICollectionViewCell {
    @IBOutlet var imageOutlet: UIImageView!
    
    var disposeBag: DisposeBag?

    var downloadableImage: Observable<DownloadableImage>?{
        didSet{
            let disposeBag = DisposeBag()

            self.downloadableImage?
                .asDriver(onErrorJustReturn: DownloadableImage.offlinePlaceholder)
                .drive(imageOutlet.rx.downloadableImageAnimated(kCATransitionFade))
                .disposed(by: disposeBag)

            self.disposeBag = disposeBag
        }
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        
        downloadableImage = nil
        disposeBag = nil
    }

    deinit {
    }
}

extension Reactive where Base: UIImageView {
    
    var downloadableImage: Binder<DownloadableImage>{
        return downloadableImageAnimated(nil)
    }
    
    func downloadableImageAnimated(_ transitionType:String?) -> Binder<DownloadableImage> {
        return Binder(base) { imageView, image in
            for subview in imageView.subviews {
                subview.removeFromSuperview()
            }
            switch image {
            case .content(let image):
                (imageView as UIImageView).rx.image.on(.next(image))
            case .offlinePlaceholder:
                let label = UILabel(frame: imageView.bounds)
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 35)
                label.text = "⚠️"
                imageView.addSubview(label)
            }
        }
    }
}
