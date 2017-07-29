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

    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = url else { return }
        webView.loadRequest(URLRequest(url: url))
    }

}

extension WebViewController: UIWebViewDelegate {

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.url?.scheme == Constant.URL.scheme {
            performSegue(withIdentifier: Constant.Segue.webviewUnwind.rawValue, sender: nil)
            return false
        }
        return true
    }

}
