//
//  SearchViewController.swift
//  Wukong
//
//  Created by Qusic on 8/16/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import SafariServices
import Cartography

class SearchViewController: UICollectionViewController {

    fileprivate var data = Data()
    fileprivate struct Data {
        var results: [[String: Any]] = []
    }

    fileprivate lazy var searchBar: UISearchBar = {
        let view = UISearchBar()
        view.delegate = self
        return view
    }()
    fileprivate var searchBarCell: UICollectionViewCell?

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
        guard let collectionView = collectionView else { return }
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.register(PlaylistSongCell.self, forCellWithReuseIdentifier: String(describing: PlaylistSongCell.self))
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UISearchBar.self))
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionViewLayout.invalidateLayout()
        })
    }

}

extension SearchViewController: UICollectionViewDelegateFlowLayout {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return data.results.count
        default: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            if let searchBarCell = searchBarCell {
                return searchBarCell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UISearchBar.self), for: indexPath)
                cell.contentView.addSubview(searchBar)
                constrain(cell.contentView, searchBar) { (view, searchBar) in
                    searchBar.edges == view.edges
                }
                searchBarCell = cell
                return cell
            }
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PlaylistSongCell.self), for: indexPath)
            if let cell = cell as? PlaylistSongCell {
                cell.setData(song: data.results[indexPath.item])
            }
            return cell
        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0: return CGSize(width: collectionView.bounds.size.width, height: 44)
        case 1: return CGSize(width: collectionView.bounds.size.width - 24, height: 32)
        default: return CGSize.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case 0: return UIEdgeInsets.zero
        case 1: return UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        default: return UIEdgeInsets.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch section {
        case 0: return 0
        case 1: return 8
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch section {
        case 0: return 0
        case 1: return 8
        default: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
        switch indexPath.section {
        case 0:
            break
        case 1:
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
        default:
            break
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }

}

extension SearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            WukongClient.sharedInstance.dispatchAction([.Search, .keyword], [searchText])
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            WukongClient.sharedInstance.dispatchAction([.Search, .keyword], [searchText])
        }
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
                    self.collectionView?.reloadSections(IndexSet(integer: 1))
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

