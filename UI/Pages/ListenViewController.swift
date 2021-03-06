import UIKit
import SafariServices

class ListenViewController: UICollectionViewController {

    private var data = Data()
    private struct Data {
        var channel = ""
        var playingId = ""
        var preloadId = ""
        var time = 0.0
        var reload = false
        var files: [Constant.Selector: String] = [:]
        var playing: [Constant.State: String] = [:]
        var running = false
        var elapsed = 0.0
        var duration = 0.0
        var lyrics: [String] = []
        var members: [[String: Any]] = []
        var playerIndex = -1
        var playlist: [[String: Any]] = []
    }

    private var cells: [IndexPath: UICollectionViewCell] = [:]

    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        title = "Wukong"
        tabBarItem = UITabBarItem(title: "Listen", image: #imageLiteral(resourceName: "ListenUnselected"), selectedImage: #imageLiteral(resourceName: "ListenSelected"))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Join", style: .plain, target: self, action: #selector(channelButtonAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(shuffleButtonAction))
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let collectionView = collectionView else { return }
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.register(PlayingSongCell.self, forCellWithReuseIdentifier: String(describing: PlayingSongCell.self))
        collectionView.register(CurrentLyricsCell.self, forCellWithReuseIdentifier: String(describing: CurrentLyricsCell.self))
        collectionView.register(ChannelMembersCell.self, forCellWithReuseIdentifier: String(describing: ChannelMembersCell.self))
        collectionView.register(PlaylistSongCell.self, forCellWithReuseIdentifier: String(describing: PlaylistSongCell.self))
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionViewLayout.invalidateLayout()
        })
    }

}

extension ListenViewController: UICollectionViewDelegateFlowLayout {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return data.playlist.count
        default: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.item {
            case 0:
                let cell = cells[indexPath] ?? collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PlayingSongCell.self), for: indexPath)
                cells[indexPath] = cell
                (cell as? PlayingSongCell)?.setData(id: data.playingId, song: data.playing, artworkFile: data.files[.playingArtwork], running: data.running, elapsed: data.elapsed, duration: data.duration)
                return cell
            case 1:
                let cell = cells[indexPath] ?? collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CurrentLyricsCell.self), for: indexPath)
                cells[indexPath] = cell
                (cell as? CurrentLyricsCell)?.setData(lyrics: data.lyrics)
                return cell
            case 2:
                let cell = cells[indexPath] ?? collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ChannelMembersCell.self), for: indexPath)
                cells[indexPath] = cell
                (cell as? ChannelMembersCell)?.setData(members: data.members, highlightedIndex: data.playerIndex)
                return cell
            default:
                return UICollectionViewCell()
            }
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PlaylistSongCell.self), for: indexPath)
            (cell as? PlaylistSongCell)?.setData(song: data.playlist[indexPath.item], showIcon: false)
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
        case 0:
            let columnCount = min(max(Int(sectionWidth / 300), 1), 2)
            let columnWidth = (sectionWidth - interitemSpacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
            switch columnCount {
            case 1:
                switch indexPath.item {
                case 0: return CGSize(width: columnWidth, height: 96)
                case 1: return CGSize(width: columnWidth, height: 30)
                case 2: return CGSize(width: columnWidth, height: 64)
                default: return CGSize.zero
                }
            case 2:
                switch indexPath.item {
                case 0: return CGSize(width: columnWidth, height: 96)
                case 1: return CGSize(width: columnWidth, height: 96)
                case 2: return CGSize(width: sectionWidth, height: 64)
                default: return CGSize.zero
                }
            default: return CGSize.zero
            }
        case 1:
            let columnCount = min(max(UInt(sectionWidth / 300), 1), 3)
            let columnWidth = (sectionWidth - interitemSpacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
            return CGSize(width: columnWidth, height: 32)
        default: return CGSize.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case 0: return UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        case 1: return UIEdgeInsets(top: 0, left: 12, bottom: 12, right: 12)
        default: return UIEdgeInsets.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch section {
        case 0: return 12
        case 1: return 8
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch section {
        case 0: return 12
        case 1: return 8
        default: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        switch indexPath.section {
        case 0:
            switch indexPath.item {
            case 0:
                sheet.title = data.playing[.title]
                if let url = URL(string: self.data.playing[.link] ?? "") {
                    sheet.addAction(UIAlertAction(title: "Track Page", style: .default) { (action) in
                        let viewController = SFSafariViewController(url: url)
                        viewController.hidesBottomBarWhenPushed = true
                        self.navigationController?.pushViewController(viewController, animated: true)
                    })
                }
                if let url = URL(string: self.data.playing[.mvLink] ?? "") {
                    sheet.addAction(UIAlertAction(title: "Video Page", style: .default) { (action) in
                        let viewController = SFSafariViewController(url: url)
                        viewController.hidesBottomBarWhenPushed = true
                        self.navigationController?.pushViewController(viewController, animated: true)
                    })
                }
                if let url = URL(string: self.data.files[.playingArtwork] ?? "") {
                    sheet.addAction(UIAlertAction(title: "Artwork File", style: .default) { (action) in
                        let viewController = SFSafariViewController(url: url)
                        viewController.hidesBottomBarWhenPushed = true
                        self.navigationController?.pushViewController(viewController, animated: true)
                    })
                }
                if let url = URL(string: self.data.files[.playingFile] ?? "") {
                    sheet.addAction(UIAlertAction(title: "Audio File", style: .default) { (action) in
                        let viewController = SFSafariViewController(url: url)
                        viewController.hidesBottomBarWhenPushed = true
                        self.navigationController?.pushViewController(viewController, animated: true)
                    })
                }
                sheet.addAction(UIAlertAction(title: "Downvote", style: .default) { (action) in
                    WukongClient.sharedInstance.dispatchAction([.Player, .downvote], [])
                })
            default:
                break
            }
        case 1:
            let item = data.playlist[indexPath.item]
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
            if let id = item[Constant.State.id.rawValue] as? String {
                sheet.addAction(UIAlertAction(title: "Upnext", style: .default) { (action) in
                    WukongClient.sharedInstance.dispatchAction([.Song, .move], [id, 0])
                })
                sheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { (action) in
                    WukongClient.sharedInstance.dispatchAction([.Song, .remove], [id])
                })
            }
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

    @objc func channelButtonAction() {
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

    @objc func shuffleButtonAction() {
        WukongClient.sharedInstance.dispatchAction([.Song, .shuffle], [])
    }

}

extension ListenViewController: AppComponent {

    func appDidLoad() {
        data = Data()
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
                    let reload = self.data.reload
                    if !playingId.isEmpty {
                        let dataLoader = DataLoader.sharedInstance
                        let audioPlayer = AudioPlayer.sharedInstance
                        let title = self.data.playing[.title]
                        let album = self.data.playing[.album]
                        let artist = self.data.playing[.artist]
                        audioPlayer.update(title: title, album: album, artist: artist, artwork: nil)
                        if let url = URL(string: self.data.files[.playingArtwork] ?? "") {
                            dataLoader.load(key: "\(playingId).\(url.pathExtension)", url: url, force: reload) { (data) in
                                guard let data = data else { return }
                                audioPlayer.update(title: title, album: album, artist: artist, artwork: UIImage(data: data))
                            }
                        }
                        if let url = URL(string: self.data.files[.playingFile] ?? "") {
                            dataLoader.load(key: "\(playingId).\(url.pathExtension)", url: url, force: reload) { (data) in
                                guard let data = data else { return }
                                var running = false
                                var elapsed = 0.0
                                var duration = 0.0
                                audioPlayer.play(data: data, time: Date(timeIntervalSince1970: self.data.time), { (nextRunning, nextElapsed, nextDuration, ended) in
                                    if running != nextRunning {
                                        audioPlayer.update()
                                        client.dispatchAction([.Player, .running], [nextRunning])
                                    }
                                    if elapsed != nextElapsed {
                                        client.dispatchAction([.Player, .elapsed], [nextElapsed])
                                    }
                                    if duration != nextDuration {
                                        client.dispatchAction([.Player, .duration], [nextDuration])
                                    }
                                    if ended {
                                        client.dispatchAction([.Player, .ended], [])
                                    }
                                    running = nextRunning
                                    elapsed = nextElapsed
                                    duration = nextDuration
                                })
                            }
                        }
                    }
                    if reload {
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
                    UIView.performWithoutAnimation {
                        self.collectionView?.reloadItems(at: [IndexPath(item: 0, section: 0)])
                    }
                }
            }
            var lyricsChanged = false
            defer {
                if lyricsChanged {
                    UIView.performWithoutAnimation {
                        self.collectionView?.reloadItems(at: [IndexPath(item: 1, section: 0)])
                    }
                }
            }
            var membersChanged = false
            defer {
                if membersChanged {
                    UIView.performWithoutAnimation {
                        self.collectionView?.reloadItems(at: [IndexPath(item: 2, section: 0)])
                    }
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
            ([.playingArtwork, .playingFile, .preloadArtwork, .preloadFile] as [Constant.Selector]).forEach { (selector) in
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
                ([.title, .album, .artist, .link, .mvLink] as [Constant.State]).forEach { (field) in
                    guard let value = playing[field.rawValue] as? String else { return }
                    playingChanged = playingChanged || self.data.playing[field] != value
                    self.data.playing[field] = value
                }
            }
            if let playing = client.querySelector(.playingFile) as [String: Any]? {
                let format = playing[Constant.State.format.rawValue] as? String ?? "unknown"
                let quality = playing[Constant.State.quality.rawValue] as? [String: Any] ?? [:]
                let qualityDescription = quality[Constant.State.description.rawValue] as? String ?? ""
                playingChanged = playingChanged || self.data.playing[.format] != format
                playingChanged = playingChanged || self.data.playing[.quality] != qualityDescription
                self.data.playing[.format] = format
                self.data.playing[.quality] = qualityDescription
            }
            if let running = client.getState([.player, .running]) as Bool?,
                let elapsed = client.getState([.player, .elapsed]) as Double?,
                let duration = client.getState([.player, .duration]) as Double? {
                playingChanged = playingChanged || self.data.running != running
                playingChanged = playingChanged || self.data.elapsed != elapsed
                playingChanged = playingChanged || self.data.duration != duration
                self.data.running = running
                self.data.elapsed = elapsed
                self.data.duration = duration
            }
            if let lyrics = client.querySelector(.currentLyrics) as [String]? {
                lyricsChanged = self.data.lyrics.elementsEqual(lyrics)
                self.data.lyrics = lyrics
            }
            if let members = client.getState([.channel, .members]) as [[String: Any]]? {
                membersChanged = !self.data.members.elementsEqual(members) {
                    let id0 = $0[Constant.State.id.rawValue] as? String
                    let id1 = $1[Constant.State.id.rawValue] as? String
                    return id0 == id1
                }
                self.data.members = members
            }
            if let playerIndex = client.querySelector(.playerIndex) as Int? {
                membersChanged = membersChanged || self.data.playerIndex != playerIndex
                self.data.playerIndex = playerIndex
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

}
