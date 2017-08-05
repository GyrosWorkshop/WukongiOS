//
//  AppController.swift
//  Wukong
//
//  Created by Qusic on 4/20/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Cartography

class AppController: UIViewController {

    fileprivate lazy var musicViewController = MusicViewController()
    fileprivate lazy var configViewController = ConfigViewController()
    fileprivate lazy var mainViewController: UIViewController = {
        let tabController = UITabBarController()
        tabController.viewControllers = [
            UINavigationController(rootViewController: self.musicViewController),
            UINavigationController(rootViewController: self.configViewController)
        ]
        return tabController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mainViewController.view)
        constrain(view, mainViewController.view) { (view, mainView) in
            view.edges == mainView.edges
        }
        WukongClient.sharedInstance.run(self)
    }

}

extension AppController: WukongDelegate {

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
