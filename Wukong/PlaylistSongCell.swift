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

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        view.textColor = .black
        return view
    }()
    private lazy var detailLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = .gray
        return view
    }()

    private var iconWidth: NSLayoutConstraint?
    private var iconMarginTrailing: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        constrain(contentView, iconView) { (view, iconView) in
            iconView.top == view.top
            iconView.bottom == view.bottom
            iconView.leading == view.leading
            iconWidth = iconView.width == 0
        }
        constrain(contentView, iconView, titleLabel) { (view, iconView, titleLabel) in
            iconMarginTrailing = titleLabel.leading == iconView.trailing
            titleLabel.trailing == view.trailing
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

    func setData(song: [String: Any], showIcon: Bool) {
        let title = song[Constant.State.title.rawValue] as? String ?? ""
        let album = song[Constant.State.album.rawValue] as? String ?? ""
        let artist = song[Constant.State.artist.rawValue] as? String ?? ""
        let siteId = song[Constant.State.siteId.rawValue] as? String ?? ""
        titleLabel.text = title
        detailLabel.text = "\(artist) − \(album)"
        switch siteId {
        case "netease-cloud-music":
            iconView.image = #imageLiteral(resourceName: "NetEase")
        case "QQMusic":
            iconView.image = #imageLiteral(resourceName: "QQ")
        case "Xiami":
            iconView.image = #imageLiteral(resourceName: "XiaMi")
        default:
            break
        }
        iconWidth?.constant = showIcon ? contentView.bounds.size.height : 0
        iconMarginTrailing?.constant = showIcon ? 8 : 0
    }

}
