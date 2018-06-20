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

    private lazy var components: [AppComponent] = [
        ListenViewController(),
        SearchViewController(),
        ConfigViewController()
    ]
    private lazy var mainViewController: UIViewController = {
        let tabController = UITabBarController()
        tabController.viewControllers = self.components
            .compactMap { $0 as? UIViewController }
            .map { UINavigationController(rootViewController: $0) }
        return tabController
    }()

    override var prefersStatusBarHidden: Bool { return false }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(mainViewController)
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
        components.forEach { $0.appDidLoad() }
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
