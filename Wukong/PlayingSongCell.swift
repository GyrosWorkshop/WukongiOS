//
//  PlayingSongCell.swift
//  Wukong
//
//  Created by Qusic on 8/12/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Cartography

class PlayingSongCell: UICollectionViewCell {

    private lazy var artworkView: ImageView = {
        let view = ImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 20)
        view.textColor = .black
        return view
    }()
    private lazy var albumLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        view.textColor = .black
        return view
    }()
    private lazy var artistLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        view.textColor = .black
        return view
    }()
    private lazy var infoLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = .gray
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(artworkView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(albumLabel)
        contentView.addSubview(artistLabel)
        contentView.addSubview(infoLabel)
        constrain(contentView, artworkView) { (view, artworkView) in
            artworkView.top == view.top
            artworkView.bottom == view.bottom
            artworkView.leading == view.leading
            artworkView.width == artworkView.height
        }
        constrain(contentView, artworkView, titleLabel) { (view, artworkView, titleLabel) in
            titleLabel.leading == artworkView.trailing + 12
            titleLabel.trailing == view.trailing
            titleLabel.bottom == artworkView.centerY - 15
        }
        constrain(titleLabel, albumLabel, artistLabel, infoLabel) { (titleLabel, albumLabel, artistLabel, infoLabel) in
            align(leading: titleLabel, albumLabel, artistLabel, infoLabel)
            align(trailing: titleLabel, albumLabel, artistLabel, infoLabel)
            albumLabel.top == titleLabel.bottom
            artistLabel.top == albumLabel.bottom
            infoLabel.top == artistLabel.bottom
        }
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }

    func setData(id: String, song: [Constant.State: String], artworkFile: String?, running: Bool, elapsed: Double, duration: Double) {
        let title = song[.title] ?? ""
        let album = song[.album] ?? ""
        let artist = song[.artist] ?? ""
        let format = song[.format] ?? ""
        let quality = song[.quality] ?? ""
        let artwork = artworkFile ?? ""
        let remaining = Int(ceil(duration - elapsed))
        titleLabel.text = title
        albumLabel.text = album
        artistLabel.text = artist
        infoLabel.text = running ? "\(String(format: "%d:%0.2d", remaining / 60, remaining % 60)) \(format) \(quality)" : ""
        if let url = URL(string: artwork) {
            artworkView.setImage(key: "\(id).\(url.pathExtension)", url: url, placeholder: #imageLiteral(resourceName: "Artwork"))
        } else {
            artworkView.setImage(placeholder: #imageLiteral(resourceName: "Artwork"))
        }
    }

}
