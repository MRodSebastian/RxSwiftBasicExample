//
//  WikipediaSearchCell.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 3/28/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public class WikipediaSearchCell: UITableViewCell {

    @IBOutlet var titleOutlet: UILabel!
    @IBOutlet var URLOutlet: UILabel!
    @IBOutlet var imagesOutlet: UICollectionView!

    var disposeBag: DisposeBag?

    let imageService = ImageServiceAPI.shared

    public override func awakeFromNib() {
        super.awakeFromNib()

        self.imagesOutlet.register(UINib(nibName: "WikipediaImageCell", bundle: nil), forCellWithReuseIdentifier: "ImageCell")
    }

    var viewModel: SearchResultsModal?{
        didSet {
            let disposeBag = DisposeBag()

            guard let viewModel = viewModel else {
                return
            }

            viewModel.title
                .map(Optional.init)
                .drive(self.titleOutlet.rx.text)
                .disposed(by: disposeBag)

            self.URLOutlet.text = viewModel.searchResult.URL.absoluteString

            viewModel.imageURLs
                .drive(self.imagesOutlet.rx.items(cellIdentifier: "ImageCell", cellType: CollectionViewImageCell.self)) { [weak self] (_, url, cell) in
                    cell.downloadableImage = self?.imageService.imageFromURL(url) ?? Observable.empty()
                }
                .disposed(by: disposeBag)
            self.disposeBag = disposeBag
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()

        self.viewModel = nil
        self.disposeBag = nil
    }

    deinit {
    }

}

fileprivate protocol ReusableView: class {
    var disposeBag: DisposeBag? { get }
    func prepareForReuse()
}

extension WikipediaSearchCell : ReusableView {

}

extension CollectionViewImageCell : ReusableView {

}
