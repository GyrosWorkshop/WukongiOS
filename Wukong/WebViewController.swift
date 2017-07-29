//
//  WebViewController.swift
//  Wukong
//
//  Created by Qusic on 7/29/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {

    var url: URL?

    private lazy var webView: UIWebView = {
        let view = UIWebView()
        view.delegate = self
        return view
    }()

    override func loadView() {
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = url else { return }
        webView.loadRequest(URLRequest(url: url))
    }

}

extension WebViewController: UIWebViewDelegate {

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.url?.scheme == Constant.URL.scheme {
            dismiss(animated: true) {
                WukongClient.sharedInstance.reload()
            }
            return false
        }
        title = request.url?.host
        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        title = webView.stringByEvaluatingJavaScript(from: "document.title")
    }

}
