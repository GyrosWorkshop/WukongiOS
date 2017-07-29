//
//  MainViewController.swift
//  Wukong
//
//  Created by Qusic on 4/20/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        WukongClient.sharedInstance.run(self)
    }

}

extension MainViewController: WukongDelegate {

    func wukongDidLoadScript() {
    }

    func wukongDidFailLoadScript() {
    }

    func wukongDidLaunch() {
        // TODO: subscribe
    }

    func wukongDidThrowException(_ exception: String) {
        print("exception:", exception) // TODO: for test
    }

    func wukongRequestOpenURL(_ url: String) {
        guard presentedViewController == nil else { return }
        guard let urlObject = URL(string: url) else { return }
        let webViewController = WebViewController()
        webViewController.url = urlObject
        present(UINavigationController(rootViewController: webViewController), animated: true)
    }

}
