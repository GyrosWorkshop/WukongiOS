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

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let type = Constant.Segue(rawValue: identifier) else { return false }
        switch type {
        case .webview:
            return presentedViewController == nil
        default:
            return true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        guard let type = Constant.Segue(rawValue: identifier) else { return }
        switch type {
        case .webview:
            guard let navigationController = segue.destination as? UINavigationController else { return }
            guard let viewController = navigationController.topViewController as? WebViewController else { return }
            guard let userInfo = sender as? String else { return }
            guard let url = URL(string: userInfo) else { return }
            viewController.url = url
        default:
            break
        }
    }

    @IBAction func prepare(unwind segue: UIStoryboardSegue) {
        guard let identifier = segue.identifier else { return }
        guard let type = Constant.Segue(rawValue: identifier) else { return }
        switch type {
        case .webviewUnwind:
            WukongClient.sharedInstance.reload()
            break
        default:
            break
        }
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
        if shouldPerformSegue(withIdentifier: Constant.Segue.webview.rawValue, sender: url) {
            performSegue(withIdentifier: Constant.Segue.webview.rawValue, sender: url)
        }
    }

}
