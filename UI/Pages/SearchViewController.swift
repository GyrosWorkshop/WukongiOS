import UIKit
import SafariServices
import Cartography

class SearchViewController: UICollectionViewController {

    private var data = Data()
    private struct Data {
        var results: [[String: Any]] = []
    }

    private var cells: [IndexPath: UICollectionViewCell] = [:]
    private lazy var searchBar: UISearchBar = {
        let view = UISearchBar()
        view.delegate = self
        return view
    }()

    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        title = "Search"
        tabBarItem = UITabBarItem(title: "Search", image: #imageLiteral(resourceName: "SearchUnselected"), selectedImage: #imageLiteral(resourceName: "SearchSelected"))
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
        super.viewWillTransition(to: size, with: coordinator)
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
            if let cell = cells[indexPath] {
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UISearchBar.self), for: indexPath)
                cells[indexPath] = cell
                cell.contentView.addSubview(searchBar)
                constrain(cell.contentView, searchBar) { (view, searchBar) in
                    searchBar.edges == view.edges
                }
                return cell
            }
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PlaylistSongCell.self), for: indexPath)
            (cell as? PlaylistSongCell)?.setData(song: data.results[indexPath.item], showIcon: true)
            return cell
        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionInset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        let interitemSpacing = self.collectionView(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: indexPath.section)
        let sectionWidth = collectionView.bounds.size.width - sectionInset.left - sectionInset.right
        switch indexPath.section {
        case 0: return CGSize(width: sectionWidth, height: 44)
        case 1:
            let columnCount = min(max(UInt(sectionWidth / 300), 1), 3)
            let columnWidth = (sectionWidth - interitemSpacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
            return CGSize(width: columnWidth, height: 32)
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
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        switch indexPath.section {
        case 0:
            break
        case 1:
            let item = data.results[indexPath.item]
            sheet.title = item[Constant.State.title.rawValue] as? String
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
        default:
            break
        }
        guard sheet.actions.count > 0 else { return }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.popoverPresentationController?.sourceView = collectionView
        sheet.popoverPresentationController?.sourceRect = collectionView.cellForItem(at: indexPath)?.frame ?? collectionView.bounds
        sheet.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        present(sheet, animated: true)
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

