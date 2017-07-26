//
//  ViewController.swift
//  Wukong
//
//  Created by Qusic on 4/20/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class ViewController: UICollectionViewController {

    fileprivate let client = WukongClient.sharedInstance

    override var prefersStatusBarHidden: Bool { return false }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
        client.run()
    }

}

extension ViewController: WukongDelegate {

    func wukongDidLoadScript() {
    }

    func wukongDidFailLoadScript() {
    }

    func wukongDidThrowException(_ exception: String) {
        print(exception)
    }

    func wukongRequestOpenURL(_ url: String) {
    }

}
