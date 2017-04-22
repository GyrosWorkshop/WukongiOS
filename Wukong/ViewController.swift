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

class ViewController: UIViewController {

    let appURL = URL(string: "https://wukongmusic.us/test")!

    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        self.addHandlers(configuration.userContentController)
        let view = WKWebView(frame: CGRect.zero, configuration: configuration)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height, left: 0, bottom: 0, right: 0)
        view.navigationDelegate = self
        view.uiDelegate = self
        return view
    }()

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(webView, at: 0)
        webView.frame = view.bounds
        webView.load(URLRequest(url: appURL))
    }

}

extension ViewController: WKScriptMessageHandler {

    func addHandlers(_ userContentController: WKUserContentController) {
        userContentController.add(self, name: "Init")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "Init":
            break
        default:
            break
        }
    }

}

extension ViewController: WKNavigationDelegate, WKUIDelegate, SFSafariViewControllerDelegate {

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            let safariController = SFSafariViewController(url: url)
            safariController.delegate = self
            present(safariController, animated: true, completion: nil)
        }
        return nil
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }

}
