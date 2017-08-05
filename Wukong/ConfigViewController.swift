//
//  ConfigViewController.swift
//  Wukong
//
//  Created by Qusic on 7/29/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class ConfigViewController: UICollectionViewController {

    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        title = "Config"
        tabBarItem = UITabBarItem(tabBarSystemItem: .more, tag: 0)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.backgroundColor = UIColor.white
    }

}
