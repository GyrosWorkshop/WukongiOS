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
        let client = WukongClient.sharedInstance
        client.subscribeChange { [unowned client, weak self] in
            guard let wself = self else { return }
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
                playlistChanged = !wself.data.playlist.elementsEqual(playlist) {
                    let id0 = $0[Constant.State.id.rawValue] as? String
                    let id1 = $1[Constant.State.id.rawValue] as? String
                    return id0 == id1
                }
                wself.data.playlist = playlist
            }
            if channelChanged {
                DispatchQueue.main.async {
                    guard let item = wself.navigationItem.leftBarButtonItem else { return }
                    item.title = wself.data.channel.isEmpty ? "Join" : "#\(wself.data.channel)"
                    wself.navigationItem.leftBarButtonItem = nil
                    wself.navigationItem.leftBarButtonItem = item
                }
            }
            if playingChanged {
                DispatchQueue.main.async {
                    wself.collectionView?.reloadSections(IndexSet(integer: 0))
                }
            }
            if playlistChanged {
                DispatchQueue.main.async {
                    wself.collectionView?.reloadSections(IndexSet(integer: 1))
                }
            }
        }
        if let channel = UserDefaults.appDefaults.string(forKey: Constant.Defaults.channel), !channel.isEmpty {
            client.dispatchAction([.Channel, .name], [channel])
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(MusicPlayingSongCell.self, forCellWithReuseIdentifier: String(describing: MusicPlayingSongCell.self))
        collectionView?.register(MusicPlaylistSongCell.self, forCellWithReuseIdentifier: String(describing: MusicPlaylistSongCell.self))
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return data.playlist.count
        default:
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MusicPlayingSongCell.self), for: indexPath)
            if let cell = cell as? MusicPlayingSongCell {
                cell.titleLabel.text = data.title
                cell.albumLabel.text = data.album
                cell.artistLabel.text = data.artist
                cell.artworkView.image = UIImage(named: "artwork")
                if let url = URL(string: data.artwork) {
                    DataLoader.sharedInstance.load(key: "\(data.id).\(url.pathExtension)", url: url) { [weak cell] (data) in
                        guard let cell = cell, let data = data else { return }
                        cell.artworkView.image = UIImage(data: data)
                    }
                }
            }
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MusicPlaylistSongCell.self), for: indexPath)
            if let cell = cell as? MusicPlaylistSongCell {
                let item = data.playlist[indexPath.item]
                let title = item[Constant.State.title.rawValue] as? String ?? ""
                let album = item[Constant.State.album.rawValue] as? String ?? ""
                let artist = item[Constant.State.artist.rawValue] as? String ?? ""
                let siteId = item[Constant.State.siteId.rawValue] as? String ?? ""
                cell.titleLabel.text = title
                cell.detailLabel.text = "\(artist) − \(album)"
                switch siteId {
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
        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0:
            return CGSize(width: collectionView.bounds.size.width, height: 120)
        case 1:
            return CGSize(width: collectionView.bounds.size.width, height: 48)
        default:
            return CGSize.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func channelButtonAction() {
        let alert = UIAlertController(title: "Join Channel", message: "Join Channel", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = self.data.channel
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { (action) in
            guard let channel = alert.textFields?.first?.text, !channel.isEmpty else { return }
            UserDefaults.appDefaults.set(channel, forKey: Constant.Defaults.channel)
            WukongClient.sharedInstance.dispatchAction([.Channel, .name], [channel])
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        present(alert, animated: true)
    }

    func shuffleButtonAction() {
        WukongClient.sharedInstance.dispatchAction([.Song, .shuffle], [])
    }

}

class MusicPlayingSongCell: UICollectionViewCell {

    lazy var artworkView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 20)
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
        contentView.addSubview(artworkView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(albumLabel)
        contentView.addSubview(artistLabel)
        constrain(contentView, artworkView) { (view, artworkView) in
            artworkView.top == view.top + 12
            artworkView.bottom == view.bottom - 12
            artworkView.leading == view.leading + 12
            artworkView.width == artworkView.height
        }
        constrain(contentView, artworkView, titleLabel) { (view, artworkView, titleLabel) in
            titleLabel.leading == artworkView.trailing + 12
            titleLabel.trailing == view.trailing - 12
            titleLabel.bottom == artworkView.centerY - 7
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
