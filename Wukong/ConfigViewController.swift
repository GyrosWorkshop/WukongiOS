//
//  ConfigViewController.swift
//  Wukong
//
//  Created by Qusic on 7/29/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class ConfigViewController: UICollectionViewController, AppComponent, UICollectionViewDelegateFlowLayout {

    fileprivate var data = Data()
    fileprivate struct Data {
        var listenOnly = false
        var connection = 0
        var audioQuality = 2
        var sync = ""
        var cookie = ""
    }

    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        title = "Config"
        tabBarItem = UITabBarItem(tabBarSystemItem: .more, tag: 0)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }

    func appDidLoad() {
        let client = WukongClient.sharedInstance
        client.subscribeChange {
            var preferencesChanged = false
            defer {
                if preferencesChanged {
                    self.collectionView?.reloadData()
                }
            }
            if let listenOnly = client.getState([.user, .preferences, .listenOnly]) as Bool? {
                preferencesChanged = preferencesChanged || self.data.listenOnly != listenOnly
                self.data.listenOnly = listenOnly
            }
            if let connection = client.getState([.user, .preferences, .connection]) as Int? {
                preferencesChanged = preferencesChanged || self.data.connection != connection
                self.data.connection = connection
            }
            if let audioQuality = client.getState([.user, .preferences, .audioQuality]) as Int? {
                preferencesChanged = preferencesChanged || self.data.audioQuality != audioQuality
                self.data.audioQuality = audioQuality
            }
            if let sync = client.getState([.user, .preferences, .sync]) as String? {
                preferencesChanged = preferencesChanged || self.data.sync != sync
                self.data.sync = sync
            }
            if let cookie = client.getState([.user, .preferences, .cookie]) as String? {
                preferencesChanged = preferencesChanged || self.data.cookie != cookie
                self.data.cookie = cookie
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionViewLayout.invalidateLayout()
        })
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 0 // TODO
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0 // TODO
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell() // TODO
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.zero // TODO
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

}
