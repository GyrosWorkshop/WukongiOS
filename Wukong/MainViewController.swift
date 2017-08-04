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

    fileprivate lazy var musicViewController = MusicViewController()
    fileprivate lazy var configViewController = ConfigViewController()
    fileprivate lazy var rootViewController: UIViewController = {
        let tabController = UITabBarController()
        tabController.viewControllers = [
            UINavigationController(rootViewController: self.musicViewController),
            UINavigationController(rootViewController: self.configViewController)
        ]
        return tabController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(rootViewController.view)
        view.addConstraints([
            NSLayoutConstraint(item: rootViewController.view, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: rootViewController.view, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: rootViewController.view, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: rootViewController.view, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0)
        ])
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
