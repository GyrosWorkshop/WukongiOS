//
//  ChannelMembersCell.swift
//  Wukong
//
//  Created by Qusic on 8/12/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Cartography

class ChannelMembersCell: UICollectionViewCell {

    fileprivate var data = Data()
    fileprivate struct Data {
        var members: [[String: Any]] = []
        var highlightedIndex: Int = -1
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = .white
        view.alwaysBounceHorizontal = true
        view.allowsSelection = false
        view.register(ChannelMemberCell.self, forCellWithReuseIdentifier: String(describing: ChannelMemberCell.self))
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(collectionView)
        constrain(contentView, collectionView) { (view, collectionView) in
            collectionView.edges == view.edges
        }
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }

    func setData(members: [[String: Any]], highlightedIndex: Int) {
        data.members = members
        data.highlightedIndex = highlightedIndex
        UIView.performWithoutAnimation {
            collectionView.reloadSections(IndexSet(integer: 0))
        }
        guard 0 ..< members.count ~= highlightedIndex else { return }
        guard let cell = collectionView.cellForItem(at: IndexPath(item: highlightedIndex, section: 0)) else { return }
        collectionView.scrollRectToVisible(cell.frame, animated: true)
    }

}

extension ChannelMembersCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.members.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ChannelMemberCell.self), for: indexPath)
        if let cell = cell as? ChannelMemberCell {
            cell.setData(member: data.members[indexPath.item])
            cell.isSelected = indexPath.item == data.highlightedIndex
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: collectionView.bounds.size.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

}
