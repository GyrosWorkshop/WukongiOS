//
//  AppController.swift
//  Wukong
//
//  Created by Qusic on 4/20/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit
import Cartography

protocol AppComponent: class {
    func appDidLoad()
}

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

    override var prefersStatusBarHidden: Bool { return false }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(mainViewController)
        view.addSubview(mainViewController.view)
        constrain(view, mainViewController.view) { (view, mainView) in
            mainView.edges == view.edges
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
        musicViewController.appDidLoad()
        configViewController.appDidLoad()
    }

    func wukongDidThrowException(_ exception: String) {
    }

    func wukongRequestOpenURL(_ url: String) {
        guard mainViewController.presentedViewController == nil else { return }
        guard let urlObject = URL(string: url) else { return }
        let webViewController = WebViewController()
        webViewController.url = urlObject
        let navController = UINavigationController(rootViewController: webViewController)
        mainViewController.present(navController, animated: true)
    }

}
