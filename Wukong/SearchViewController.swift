//
//  SearchViewController.swift
//  Wukong
//
//  Created by Qusic on 8/16/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import SafariServices

class SearchViewController: UICollectionViewController {

    fileprivate var data = Data()
    fileprivate struct Data {
        var results: [[String: Any]] = []
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
        collectionView?.register(PlaylistSongCell.self, forCellWithReuseIdentifier: String(describing: PlaylistSongCell.self))
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionViewLayout.invalidateLayout()
        })
    }

}

extension SearchViewController: UICollectionViewDelegateFlowLayout {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.results.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PlaylistSongCell.self), for: indexPath)
        if let cell = cell as? PlaylistSongCell {
            cell.setData(song: data.results[indexPath.item])
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width - 24, height: 32)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = data.results[indexPath.item]
        let sheet = UIAlertController(title: item[Constant.State.title.rawValue] as? String, message: nil, preferredStyle: .actionSheet)
        if let url = URL(string: item[Constant.State.link.rawValue] as? String ?? "") {
            sheet.addAction(UIAlertAction(title: "Track Page", style: .default) { (action) in
                let viewController = SFSafariViewController(url: url)
                viewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(viewController, animated: true)
            })
        }
        if let url = URL(string: item[Constant.State.mvLink.rawValue] as? String ?? "") {
            sheet.addAction(UIAlertAction(title: "Video Page", style: .default) { (action) in
                let viewController = SFSafariViewController(url: url)
                viewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(viewController, animated: true)
            })
        }
        sheet.addAction(UIAlertAction(title: "Upnext", style: .default) { (action) in
            WukongClient.sharedInstance.dispatchAction([.Song, .add], [item])
        })
        guard sheet.actions.count > 0 else { return }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

}

extension SearchViewController: AppComponent {

    func appDidLoad() {
        data = Data()
        let client = WukongClient.sharedInstance
        client.subscribeChange {
            var resultsChanged = false
            defer {
                if resultsChanged {
                    self.collectionView?.reloadSections(IndexSet(integer: 0))
                }
            }
            if let results = client.getState([.search, .results]) as [[String: Any]]? {
                resultsChanged = !self.data.results.elementsEqual(results) {
                    let id0 = $0[Constant.State.id.rawValue] as? String
                    let id1 = $1[Constant.State.id.rawValue] as? String
                    return id0 == id1
                }
                self.data.results = results
            }
        }
    }
    
}

