//
//  PlaylistSongCell.swift
//  Wukong
//
//  Created by Qusic on 8/12/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Cartography

class PlaylistSongCell: UICollectionViewCell {

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
