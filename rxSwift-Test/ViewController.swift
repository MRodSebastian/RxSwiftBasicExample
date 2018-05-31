//
//  ViewController.swift
//  rxSwift-Test
//
//  Created by Manu Rodríguez on 31/5/18.
//  Copyright © 2018 Streye. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    let API = WikipediaService.shared
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
        configureNavigateOnRowClick()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func configureDataSource(){
        tableView.register(UINib(nibName: "WikipediaSearchCell", bundle: nil), forCellReuseIdentifier: "WikipediaSearchCell")
        tableView.rowHeight = 194
        tableView.tableFooterView = UIView(frame: .zero)
        
        
        let results = searchBar.rx.text.orEmpty.asDriver().throttle(0.3).distinctUntilChanged().flatMapLatest{query in
            self.API.getResults(query).retry(3).startWith([]).asDriver(onErrorJustReturn: [])
            }.map{results in
                results.map(SearchResultsModal.init)
        }
        
        
        results.drive(tableView.rx.items(cellIdentifier: "WikipediaSearchCell", cellType: WikipediaSearchCell.self)){(_, viewModel, cell) in
            cell.viewModel = viewModel
        }.disposed(by: disposeBag)
        
        results.map{
            $0.count != 0}.drive().disposed(by: disposeBag)
    }
    
    func configureNavigateOnRowClick() {
        tableView.rx.modelSelected(SearchResultsModal.self)
            .asDriver()
            .drive(onNext: { searchResult in
                UIApplication.shared.openURL(searchResult.searchResult.URL)
            })
            .disposed(by: disposeBag)
    }

}

