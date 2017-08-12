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
    lazy var infoLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.gray
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

}
