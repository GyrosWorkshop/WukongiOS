//
//  MusicViewController.swift
//  Wukong
//
//  Created by Qusic on 7/29/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Cartography

class MusicViewController: UICollectionViewController, AppViewController, UICollectionViewDelegateFlowLayout {

    fileprivate var data = Data()
    fileprivate struct Data {
        var channel: String = ""
        var id: String = ""
        var title: String = ""
        var album: String = ""
        var artist: String = ""
        var artwork: String = ""
        var link: String = ""
        var mvLink: String = ""
        var playlist: [[String: Any]] = []
    }

    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        title = "Wukong"
        tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 0)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Join", style: .plain, target: self, action: #selector(channelButtonAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(shuffleButtonAction))
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }

    func appDidLoad() {
        WukongClient.sharedInstance.subscribeChange { [weak self] in
            guard let wself = self else { return }
            let client = WukongClient.sharedInstance
            var channelChanged = false
            var playingChanged = false
            var playlistChanged = false
            if let channel = client.getState([.channel, .name]) as String?, wself.data.channel != channel {
                wself.data.channel = channel
                channelChanged = true
            }
            if let id = client.getState([.song, .playing, .id]) as String?, wself.data.id != id {
                wself.data.id = id
                playingChanged = true
            }
            if let title = client.getState([.song, .playing, .title]) as String?, wself.data.title != title {
                wself.data.title = title
                playingChanged = true
            }
            if let album = client.getState([.song, .playing, .album]) as String?, wself.data.album != album {
                wself.data.album = album
                playingChanged = true
            }
            if let artist = client.getState([.song, .playing, .artist]) as String?, wself.data.artist != artist {
                wself.data.artist = artist
                playingChanged = true
            }
            if let artwork = client.querySelector(.playingArtwork) as String?, wself.data.artwork != artwork {
                wself.data.artwork = artwork
                playingChanged = true
            }
            if let link = client.getState([.song, .playing, .link]) as String?, wself.data.link != link {
                wself.data.link = link
                playingChanged = true
            }
            if let mvLink = client.getState([.song, .playing, .mvLink]) as String?, wself.data.mvLink != mvLink {
                wself.data.mvLink = mvLink
                playingChanged = true
            }
            if let playlist = client.getState([.song, .playlist]) as [[String: Any]]? {
                wself.data.playlist = playlist
                playlistChanged = !wself.data.playlist.elementsEqual(playlist) {
                    let id0 = $0[Constant.State.id.rawValue] as? String
                    let id1 = $1[Constant.State.id.rawValue] as? String
                    return id0 == id1
                }
            }
            if channelChanged {
                DispatchQueue.main.async {
                    guard let item = wself.navigationItem.leftBarButtonItem else { return }
                    item.title = wself.data.channel.isEmpty ? "Join" : wself.data.channel
                    wself.navigationItem.leftBarButtonItem = nil
                    wself.navigationItem.leftBarButtonItem = item
                }
            }
            if playingChanged {
                DispatchQueue.main.async {
                    // TODO
                    guard let layout = wself.collectionViewLayout as? UICollectionViewFlowLayout else { return }
                    let invalidation = UICollectionViewFlowLayoutInvalidationContext()
                    invalidation.invalidateSupplementaryElements(ofKind: UICollectionElementKindSectionHeader, at: [IndexPath(item: 0, section: 0)])
                    layout.invalidateLayout(with: invalidation)
                }
            }
            if playlistChanged {
                DispatchQueue.main.async {
                    wself.collectionView?.reloadSections(IndexSet(integer: 0))
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(MusicPlayingSongView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: String(describing: MusicPlayingSongView.self))
        collectionView?.register(MusicPlaylistSongCell.self, forCellWithReuseIdentifier: String(describing: MusicPlaylistSongCell.self))
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.playlist.count
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: MusicPlayingSongView.self), for: indexPath)
        if let view = view as? MusicPlayingSongView {
            view.titleLabel.text = data.title
            view.albumLabel.text = data.album
            view.artistLabel.text = data.artist
            view.artworkView.image = UIImage(named: "artwork")
            if let url = URL(string: data.artwork) {
                DataLoader.sharedInstance.load(key: "\(data.id).\(url.pathExtension)", url: url) { [weak view] (data) in
                    guard let view = view, let data = data else { return }
                    view.artworkView.image = UIImage(data: data)
                }
            }
        }
        return view
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MusicPlaylistSongCell.self), for: indexPath)
        if let cell = cell as? MusicPlaylistSongCell {
            let item = data.playlist[indexPath.item]
            let title = item[Constant.State.title.rawValue] as? String ?? ""
            let album = item[Constant.State.album.rawValue] as? String ?? ""
            let artist = item[Constant.State.artist.rawValue] as? String ?? ""
            let siteId = item[Constant.State.siteId.rawValue] as? String ?? ""
            cell.titleLabel.text = title
            cell.detailLabel.text = "\(artist) − \(album)"
            switch siteId { // TODO
            case "netease-cloud-music":
                cell.iconView.image = UIImage(named: "netease")
            case "QQMusic":
                cell.iconView.image = UIImage(named: "qq")
            case "Xiami":
                cell.iconView.image = UIImage(named: "xiami")
            default:
                break
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 120)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 48)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func channelButtonAction() {
        WukongClient.sharedInstance.dispatchAction([.Channel, .name], [""])
        // TODO
    }

    func shuffleButtonAction() {
        // TODO
    }

}

class MusicPlayingSongView: UICollectionReusableView {

    lazy var artworkView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 18)
        view.textColor = UIColor.black
        return view
    }()
    lazy var albumLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        view.textColor = UIColor.black
        return view
    }()
    lazy var artistLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        view.textColor = UIColor.black
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(artworkView)
        addSubview(titleLabel)
        addSubview(albumLabel)
        addSubview(artistLabel)
        constrain(self, artworkView) { (view, artworkView) in
            artworkView.top == view.top + 12
            artworkView.bottom == view.bottom - 12
            artworkView.leading == view.leading + 12
            artworkView.width == artworkView.height
        }
        constrain(self, artworkView, titleLabel) { (view, artworkView, titleLabel) in
            titleLabel.leading == artworkView.trailing + 12
            titleLabel.trailing == view.trailing - 12
            titleLabel.bottom == artworkView.centerY
        }
        constrain(titleLabel, albumLabel, artistLabel) { (titleLabel, albumLabel, artistLabel) in
            align(leading: titleLabel, albumLabel, artistLabel)
            align(trailing: titleLabel, albumLabel, artistLabel)
            albumLabel.top == titleLabel.bottom
            artistLabel.top == albumLabel.bottom
        }
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }

}

class MusicPlaylistSongCell: UICollectionViewCell {

    lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        view.textColor = UIColor.black
        return view
    }()
    lazy var detailLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UIColor.gray
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        constrain(contentView, iconView) { (view, iconView) in
            iconView.top == view.top + 8
            iconView.bottom == view.bottom - 8
            iconView.leading == view.leading + 12
            iconView.width == iconView.height
        }
        constrain(contentView, iconView, titleLabel) { (view, iconView, titleLabel) in
            titleLabel.leading == iconView.trailing + 8
            titleLabel.trailing == view.trailing - 12
            titleLabel.bottom == iconView.centerY + 1
        }
        constrain(titleLabel, detailLabel) { (titleLabel, detailLabel) in
            align(leading: titleLabel, detailLabel)
            align(trailing: titleLabel, detailLabel)
            detailLabel.top == titleLabel.bottom
        }
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }

}
