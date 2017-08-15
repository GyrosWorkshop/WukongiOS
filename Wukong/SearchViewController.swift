//
//  SearchViewController.swift
//  Wukong
//
//  Created by Qusic on 8/16/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class SearchViewController: UICollectionViewController {

    fileprivate var data = Data()
    fileprivate struct Data {
        //TODO
    }

    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        title = "Search"
        tabBarItem = UITabBarItem(title: "Search", image: UIImage(named: "search0"), selectedImage: UIImage(named: "search1"))
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        //TODO
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionViewLayout.invalidateLayout()
        })
    }

}

extension SearchViewController: UICollectionViewDelegateFlowLayout {

    //TODO

}

extension SearchViewController: AppComponent {

    func appDidLoad() {
        data = Data()
        let client = WukongClient.sharedInstance
        client.subscribeChange {
            //TODO
        }
    }
    
}

