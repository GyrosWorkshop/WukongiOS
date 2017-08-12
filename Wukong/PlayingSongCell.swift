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
