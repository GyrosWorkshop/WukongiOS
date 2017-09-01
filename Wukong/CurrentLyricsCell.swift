//
//  CurrentLyricsCell.swift
//  Wukong
//
//  Created by Qusic on 8/12/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Cartography

class CurrentLyricsCell: UICollectionViewCell {

    private lazy var label: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = .black
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        constrain(contentView, label) { (view, label) in
            label.edges == view.edges
        }
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }

    func setData(lyrics: [String]) {
        label.text = lyrics.joined(separator: "\n")
    }

}
