//
//  MusicViewController.swift
//  Wukong
//
//  Created by Qusic on 7/29/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Cartography

class MusicViewController: UICollectionViewController, AppComponent, UICollectionViewDelegateFlowLayout {

    fileprivate var data = Data()
    fileprivate struct Data {
        var channel = ""
        var playingId = ""
        var preloadId = ""
        var time = 0.0
        var reload = false
        var files: [Constant.Selector: String] = [:]
        var playing: [Constant.State: String] = [:]
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
        client.subscribeChange {
            var channelChanged = false
            defer {
                if channelChanged {
                    if let item = self.navigationItem.leftBarButtonItem {
                        let channel = self.data.channel
                        item.title = channel.isEmpty ? "Join" : "#\(channel)"
                        self.navigationItem.leftBarButtonItem = nil
                        self.navigationItem.leftBarButtonItem = item
                    }
                }
            }
            var trackChanged = false
            defer {
                if trackChanged {
                    let playingId = self.data.playingId
                    if !playingId.isEmpty {
                        let dataLoader = DataLoader.sharedInstance
                        let audioPlayer = AudioPlayer.sharedInstance
                        let title = self.data.playing[.title]
                        let album = self.data.playing[.album]
                        let artist = self.data.playing[.artist]
                        audioPlayer.update(title: title, album: album, artist: artist, artwork: nil)
                        if let url = URL(string: self.data.files[.playingArtwork] ?? "") {
                            dataLoader.load(key: "\(playingId).\(url.pathExtension)", url: url) { (data) in
                                guard let data = data else { return }
                                audioPlayer.update(title: title, album: album, artist: artist, artwork: UIImage(data: data))
                            }
                        }
                        if let url = URL(string: self.data.files[.playingFile] ?? "") {
                            dataLoader.load(key: "\(playingId).\(url.pathExtension)", url: url) { (data) in
                                guard let data = data else { return }
                                var running = false
                                var elapsed = 0.0
                                var duration = 0.0
                                audioPlayer.play(data: data, time: Date(timeIntervalSince1970: self.data.time), { (player) in
                                    let nextRunning = player?.isPlaying ?? false
                                    let nextElapsed = player?.currentTime ?? 0.0
                                    let nextDuration = player?.duration ?? 0.0
                                    if running != nextRunning {
                                        client.dispatchAction([.Player, .running], [nextRunning])
                                    }
                                    if elapsed != nextElapsed {
                                        client.dispatchAction([.Player, .elapsed], [nextElapsed])
                                    }
                                    if duration != nextDuration {
                                        client.dispatchAction([.Player, .duration], [nextDuration])
                                    }
                                    if running && !nextRunning && duration - elapsed < 1 {
                                        client.dispatchAction([.Player, .ended], [])
                                    }
                                    running = nextRunning
                                    elapsed = nextElapsed
                                    duration = nextDuration
                                })
                            }
                        }
                    }
                    if self.data.reload {
                        client.dispatchAction([.Player, .reload], [false])
                    }
                }
            }
            var preloadChanged = false
            defer {
                if preloadChanged {
                    let preloadId = self.data.preloadId
                    if !preloadId.isEmpty {
                        let dataLoader = DataLoader.sharedInstance
                        if let url = URL(string: self.data.files[.preloadArtwork] ?? "") {
                            dataLoader.load(key: "\(preloadId).\(url.pathExtension)", url: url)
                        }
                        if let url = URL(string: self.data.files[.preloadFile] ?? "") {
                            dataLoader.load(key: "\(preloadId).\(url.pathExtension)", url: url)
                        }
                    }
                }
            }
            var playingChanged = false
            defer {
                if playingChanged {
                    self.collectionView?.reloadSections(IndexSet(integer: 0))
                }
            }
            var playlistChanged = false
            defer {
                if playlistChanged {
                    self.collectionView?.reloadSections(IndexSet(integer: 1))
                }
            }
            if let channel = client.getState([.channel, .name]) as String? {
                channelChanged = self.data.channel != channel
                self.data.channel = channel
            }
            if let playingId = client.getState([.song, .playing, .id]) as String?,
                let preloadId = client.getState([.song, .preload, .id]) as String?,
                let time = client.getState([.song, .playing, .time]) as Double?,
                let reload = client.getState([.player, .reload]) as Bool? {
                trackChanged = reload || self.data.playingId != playingId || abs(self.data.time - time) > 10
                preloadChanged = self.data.preloadId != preloadId
                self.data.playingId = playingId
                self.data.preloadId = preloadId
                self.data.time = time
                self.data.reload = reload
            }
            let selectors: [Constant.Selector] = [.playingArtwork, .playingFile, .preloadArtwork, .preloadFile]
            selectors.forEach { (selector) in
                guard let value = client.querySelector(selector) as Any? else { return }
                switch value {
                case let string as String:
                    self.data.files[selector] = string
                case let object as [String: Any]:
                    self.data.files[selector] = object[Constant.State.url.rawValue] as? String ?? ""
                default:
                    self.data.files[selector] = ""
                }
            }
            if let playing = client.getState([.song, .playing]) as [String: Any]? {
                let fields: [Constant.State] = [.title, .album, .artist, .link, .mvLink]
                fields.forEach { (field) in
                    guard let value = playing[field.rawValue] as? String else { return }
                    playingChanged = playingChanged || self.data.playing[field] != value
                    self.data.playing[field] = value
                }
            }
            if let playing = client.querySelector(.playingFile) as [String: Any]? {
                let format = playing[Constant.State.format.rawValue] as? String ?? "unknown"
                let quality = playing[Constant.State.quality.rawValue] as? [String: Any] ?? [:]
                let qualityDescription = quality[Constant.State.description.rawValue] as? String ?? ""
                self.data.playing[.format] = format
                self.data.playing[.quality] = qualityDescription
            }
            if let playlist = client.getState([.song, .playlist]) as [[String: Any]]? {
                playlistChanged = !self.data.playlist.elementsEqual(playlist) {
                    let id0 = $0[Constant.State.id.rawValue] as? String
                    let id1 = $1[Constant.State.id.rawValue] as? String
                    return id0 == id1
                }
                self.data.playlist = playlist
            }
        }
        if let channel = UserDefaults.appDefaults.string(forKey: Constant.Defaults.channel), !channel.isEmpty {
            client.dispatchAction([.Channel, .name], [channel])
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(MusicPlayingSongCell.self, forCellWithReuseIdentifier: String(describing: MusicPlayingSongCell.self))
        collectionView?.register(MusicPlaylistSongCell.self, forCellWithReuseIdentifier: String(describing: MusicPlaylistSongCell.self))
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionViewLayout.invalidateLayout()
        })
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
                let title = data.playing[.title] ?? ""
                let album = data.playing[.album] ?? ""
                let artist = data.playing[.artist] ?? ""
                let artwork = data.files[.playingArtwork] ?? ""
                cell.titleLabel.text = title
                cell.albumLabel.text = album
                cell.artistLabel.text = artist
                cell.artworkView.image = UIImage(named: "artwork")
                if let url = URL(string: artwork) {
                    DataLoader.sharedInstance.load(key: "\(data.playingId).\(url.pathExtension)", url: url) { [weak cell] (data) in
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
        let alert = UIAlertController(title: "Join Channel", message: nil, preferredStyle: .alert)
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
        view.clipsToBounds = true
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
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
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
