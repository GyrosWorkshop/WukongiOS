//
//  ChannelMemberCell.swift
//  Wukong
//
//  Created by Qusic on 8/12/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Cartography

class ChannelMemberCell: UICollectionViewCell {

    lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    lazy var nameLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UIColor.black
        view.textAlignment = .center
        view.adjustsFontSizeToFitWidth = true
        view.minimumScaleFactor = 0.6
        return view
    }()

    override var isSelected: Bool {
        didSet {
            nameLabel.font = isSelected ? UIFont.boldSystemFont(ofSize: 14) : UIFont.systemFont(ofSize: 14)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        constrain(contentView, avatarView) { (view, avatarView) in
            avatarView.top == view.top
            avatarView.width == avatarView.height
            avatarView.centerX == view.centerX
        }
        constrain(contentView, nameLabel) { (view, nameLabel) in
            nameLabel.bottom == view.bottom
            nameLabel.leading == view.leading
            nameLabel.trailing == view.trailing
        }
        constrain(avatarView, nameLabel) { (avatarView, nameLabel) in
            avatarView.bottom == nameLabel.top
        }
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarView.layer.cornerRadius = avatarView.bounds.size.width / 2
    }

}
