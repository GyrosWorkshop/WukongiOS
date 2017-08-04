//
//  MusicViewController.swift
//  Wukong
//
//  Created by Qusic on 7/29/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class MusicViewController: UICollectionViewController {

    init() {
        let layout = UICollectionViewFlowLayout()
        super.init(collectionViewLayout: layout)
        title = "Wukong"
        tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 0)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
