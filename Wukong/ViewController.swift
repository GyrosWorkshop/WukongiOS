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

    fileprivate struct Constant {
        static let rootURL = URL(string: "https://wukongmusic.us")!
    }

    fileprivate let client = WukongClient.sharedInstance
    fileprivate let defaults = UserDefaults.standard

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

}
